use axum::http::{header, Method, HeaderValue};
use tower_http::cors::CorsLayer;

pub fn cors_layer() -> CorsLayer {
    CorsLayer::new()
        .allow_origin("http://localhost:3000".parse::<HeaderValue>().unwrap())
        .allow_methods([Method::GET, Method::POST, Method::PUT, Method::DELETE])
        .allow_headers([header::CONTENT_TYPE, header::AUTHORIZATION])
        .allow_credentials(true)
}
