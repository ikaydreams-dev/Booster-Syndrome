use axum::{
    routing::{get, post},
    Router,
    Json,
    http::StatusCode,
    extract::State,
};
use serde::{Deserialize, Serialize};
use sqlx::postgres::PgPoolOptions;
use std::sync::Arc;
use tower_http::cors::CorsLayer;
use tracing::{info, error};

mod handlers;
mod models;
mod services;
mod middleware;
mod utils;

#[derive(Clone)]
pub struct AppState {
    db: sqlx::PgPool,
}

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    dotenv::dotenv().ok();

    tracing_subscriber::fmt()
        .with_max_level(tracing::Level::INFO)
        .init();

    let database_url = std::env::var("DATABASE_URL")
        .unwrap_or_else(|_| "postgres://localhost/auth_db".to_string());

    info!("Connecting to database...");
    let pool = PgPoolOptions::new()
        .max_connections(5)
        .connect(&database_url)
        .await?;

    info!("Running database migrations...");
    sqlx::migrate!("./migrations").run(&pool).await?;

    let state = Arc::new(AppState { db: pool });

    let app = Router::new()
        .route("/health", get(health_check))
        .route("/api/v1/auth/register", post(handlers::auth::register))
        .route("/api/v1/auth/login", post(handlers::auth::login))
        .route("/api/v1/auth/refresh", post(handlers::auth::refresh_token))
        .route("/api/v1/auth/logout", post(handlers::auth::logout))
        .route("/api/v1/auth/verify", get(handlers::auth::verify_token))
        .layer(CorsLayer::permissive())
        .with_state(state);

    let addr = "0.0.0.0:8001";
    info!("Auth service listening on {}", addr);

    let listener = tokio::net::TcpListener::bind(addr).await?;
    axum::serve(listener, app).await?;

    Ok(())
}

async fn health_check() -> Json<serde_json::Value> {
    Json(serde_json::json!({
        "status": "healthy",
        "service": "auth-service",
        "version": "1.0.0"
    }))
}
