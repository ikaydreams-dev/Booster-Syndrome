use axum::{
    routing::{get, post},
    Router,
    Json,
};
use tower_http::cors::CorsLayer;
use tracing::{info};

mod handlers;
mod storage;

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    dotenv::dotenv().ok();

    tracing_subscriber::fmt()
        .with_max_level(tracing::Level::INFO)
        .init();

    let app = Router::new()
        .route("/health", get(health_check))
        .route("/api/v1/files/upload", post(handlers::upload_file))
        .route("/api/v1/files/:id", get(handlers::get_file))
        .route("/api/v1/files/:id", axum::routing::delete(handlers::delete_file))
        .layer(CorsLayer::permissive());

    let addr = "0.0.0.0:8005";
    info!("File service listening on {}", addr);

    let listener = tokio::net::TcpListener::bind(addr).await?;
    axum::serve(listener, app).await?;

    Ok(())
}

async fn health_check() -> Json<serde_json::Value> {
    Json(serde_json::json!({
        "status": "healthy",
        "service": "file-service",
        "version": "1.0.0"
    }))
}
