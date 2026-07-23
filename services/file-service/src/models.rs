use serde::{Deserialize, Serialize};
use uuid::Uuid;
use chrono::{DateTime, Utc};

#[derive(Debug, Serialize, Deserialize)]
pub struct FileMetadata {
    pub id: Uuid,
    pub filename: String,
    pub size: usize,
    pub content_type: String,
    pub s3_key: String,
    pub uploaded_by: Option<Uuid>,
    pub uploaded_at: DateTime<Utc>,
}

#[derive(Debug, Serialize)]
pub struct FileUploadResponse {
    pub file_id: Uuid,
    pub filename: String,
    pub size: usize,
    pub url: String,
}

#[derive(Debug, Deserialize)]
pub struct FileListQuery {
    pub page: Option<u32>,
    pub limit: Option<u32>,
    pub user_id: Option<Uuid>,
}
