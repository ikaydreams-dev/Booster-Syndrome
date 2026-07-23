use axum::{
    extract::State,
    http::StatusCode,
    Json,
};
use serde_json::{json, Value};
use std::sync::Arc;
use validator::Validate;

use crate::{
    models::{RegisterRequest, LoginRequest, UserResponse},
    services::auth_service,
    AppState,
};

pub async fn register(
    State(state): State<Arc<AppState>>,
    Json(payload): Json<RegisterRequest>,
) -> Result<(StatusCode, Json<Value>), (StatusCode, Json<Value>)> {
    payload.validate().map_err(|e| {
        (
            StatusCode::BAD_REQUEST,
            Json(json!({"error": format!("Validation error: {}", e)})),
        )
    })?;

    match auth_service::register_user(&state.db, payload).await {
        Ok((user, tokens)) => Ok((
            StatusCode::CREATED,
            Json(json!({
                "user": UserResponse::from(user),
                "tokens": tokens
            })),
        )),
        Err(e) => Err((
            StatusCode::INTERNAL_SERVER_ERROR,
            Json(json!({"error": e.to_string()})),
        )),
    }
}

pub async fn login(
    State(state): State<Arc<AppState>>,
    Json(payload): Json<LoginRequest>,
) -> Result<(StatusCode, Json<Value>), (StatusCode, Json<Value>)> {
    payload.validate().map_err(|e| {
        (
            StatusCode::BAD_REQUEST,
            Json(json!({"error": format!("Validation error: {}", e)})),
        )
    })?;

    match auth_service::login_user(&state.db, payload).await {
        Ok((user, tokens)) => Ok((
            StatusCode::OK,
            Json(json!({
                "user": UserResponse::from(user),
                "tokens": tokens
            })),
        )),
        Err(e) => Err((
            StatusCode::UNAUTHORIZED,
            Json(json!({"error": e.to_string()})),
        )),
    }
}

pub async fn refresh_token(
    State(state): State<Arc<AppState>>,
    Json(payload): Json<crate::models::RefreshTokenRequest>,
) -> Result<(StatusCode, Json<Value>), (StatusCode, Json<Value>)> {
    match auth_service::refresh_access_token(&state.db, &payload.refresh_token).await {
        Ok(tokens) => Ok((StatusCode::OK, Json(json!(tokens)))),
        Err(e) => Err((
            StatusCode::UNAUTHORIZED,
            Json(json!({"error": e.to_string()})),
        )),
    }
}

pub async fn logout(
    State(state): State<Arc<AppState>>,
    Json(payload): Json<crate::models::RefreshTokenRequest>,
) -> Result<(StatusCode, Json<Value>), (StatusCode, Json<Value>)> {
    match auth_service::logout_user(&state.db, &payload.refresh_token).await {
        Ok(_) => Ok((
            StatusCode::OK,
            Json(json!({"message": "Logged out successfully"})),
        )),
        Err(e) => Err((
            StatusCode::INTERNAL_SERVER_ERROR,
            Json(json!({"error": e.to_string()})),
        )),
    }
}

pub async fn verify_token(
    State(state): State<Arc<AppState>>,
) -> Result<(StatusCode, Json<Value>), (StatusCode, Json<Value>)> {
    Ok((
        StatusCode::OK,
        Json(json!({"message": "Token is valid"})),
    ))
}
