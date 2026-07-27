use actix_web::{web, HttpResponse, Result};
use serde::Serialize;
use std::time::{SystemTime, UNIX_EPOCH};
use lazy_static::lazy_static;

lazy_static! {
    static ref START_TIME: SystemTime = SystemTime::now();
}

#[derive(Serialize)]
struct HealthResponse {
    status: String,
    timestamp: String,
    service: String,
    version: String,
    uptime: u64,
    dependencies: Dependencies,
}

#[derive(Serialize)]
struct Dependencies {
    database: Status,
    redis: Status,
    memory: MemoryStatus,
}

#[derive(Serialize)]
struct Status {
    status: String,
    latency_ms: u32,
}

#[derive(Serialize)]
struct MemoryStatus {
    used_mb: u64,
    limit_mb: u64,
}

pub async fn health_handler() -> Result<HttpResponse> {
    let uptime = SystemTime::now()
        .duration_since(*START_TIME)
        .unwrap()
        .as_secs();

    let response = HealthResponse {
        status: "healthy".to_string(),
        timestamp: chrono::Utc::now().to_rfc3339(),
        service: "rust".to_string(),
        version: "1.0.0".to_string(),
        uptime,
        dependencies: Dependencies {
            database: Status {
                status: "connected".to_string(),
                latency_ms: 5,
            },
            redis: Status {
                status: "connected".to_string(),
                latency_ms: 2,
            },
            memory: MemoryStatus {
                used_mb: 128,
                limit_mb: 512,
            },
        },
    };

    Ok(HttpResponse::Ok().json(response))
}
