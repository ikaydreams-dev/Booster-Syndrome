use tracing::{info, warn};
use axum::{
    body::Body,
    extract::Request,
    middleware::Next,
    response::Response,
};

pub async fn logging_middleware(
    request: Request<Body>,
    next: Next,
) -> Response {
    let method = request.method().clone();
    let uri = request.uri().clone();

    info!("Incoming request: {} {}", method, uri);

    let response = next.run(request).await;

    let status = response.status();
    if status.is_client_error() || status.is_server_error() {
        warn!("Request failed: {} {} - Status: {}", method, uri, status);
    } else {
        info!("Request completed: {} {} - Status: {}", method, uri, status);
    }

    response
}
