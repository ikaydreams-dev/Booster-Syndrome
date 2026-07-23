use axum::{
    extract::{Path, Multipart},
    http::StatusCode,
    Json,
};
use serde_json::{json, Value};
use uuid::Uuid;

pub async fn upload_file(
    mut multipart: Multipart,
) -> Result<(StatusCode, Json<Value>), (StatusCode, Json<Value>)> {
    while let Some(field) = multipart.next_field().await.unwrap() {
        let name = field.name().unwrap().to_string();
        let data = field.bytes().await.unwrap();

        let file_id = Uuid::new_v4();

        return Ok((
            StatusCode::CREATED,
            Json(json!({
                "file_id": file_id,
                "filename": name,
                "size": data.len(),
                "url": format!("/api/v1/files/{}", file_id)
            })),
        ));
    }

    Err((
        StatusCode::BAD_REQUEST,
        Json(json!({"error": "No file provided"})),
    ))
}

pub async fn get_file(
    Path(id): Path<String>,
) -> Result<Json<Value>, (StatusCode, Json<Value>)> {
    Ok(Json(json!({
        "file_id": id,
        "url": format!("https://storage.example.com/{}", id)
    })))
}

pub async fn delete_file(
    Path(id): Path<String>,
) -> Result<Json<Value>, (StatusCode, Json<Value>)> {
    Ok(Json(json!({
        "message": "File deleted successfully",
        "file_id": id
    })))
}
