use std::env;

#[derive(Clone)]
pub struct Config {
    pub s3_bucket: String,
    pub s3_region: String,
    pub max_file_size: usize,
    pub allowed_extensions: Vec<String>,
}

impl Config {
    pub fn from_env() -> Self {
        Self {
            s3_bucket: env::var("S3_BUCKET").unwrap_or_else(|_| "booster-files".to_string()),
            s3_region: env::var("S3_REGION").unwrap_or_else(|_| "us-east-1".to_string()),
            max_file_size: env::var("MAX_FILE_SIZE")
                .unwrap_or_else(|_| "10485760".to_string()) // 10MB default
                .parse()
                .unwrap_or(10485760),
            allowed_extensions: env::var("ALLOWED_EXTENSIONS")
                .unwrap_or_else(|_| "jpg,jpeg,png,pdf,doc,docx".to_string())
                .split(',')
                .map(|s| s.trim().to_string())
                .collect(),
        }
    }

    pub fn is_extension_allowed(&self, extension: &str) -> bool {
        self.allowed_extensions.iter().any(|ext| ext == extension)
    }
}
