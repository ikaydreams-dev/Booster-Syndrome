use aws_sdk_s3::Client;
use aws_config;

pub struct StorageClient {
    s3_client: Client,
}

impl StorageClient {
    pub async fn new() -> Self {
        let config = aws_config::load_from_env().await;
        let s3_client = Client::new(&config);

        Self { s3_client }
    }

    pub async fn upload(&self, bucket: &str, key: &str, data: Vec<u8>) -> Result<(), String> {
        self.s3_client
            .put_object()
            .bucket(bucket)
            .key(key)
            .body(data.into())
            .send()
            .await
            .map_err(|e| e.to_string())?;

        Ok(())
    }

    pub async fn download(&self, bucket: &str, key: &str) -> Result<Vec<u8>, String> {
        let resp = self.s3_client
            .get_object()
            .bucket(bucket)
            .key(key)
            .send()
            .await
            .map_err(|e| e.to_string())?;

        let data = resp.body.collect().await.map_err(|e| e.to_string())?;
        Ok(data.into_bytes().to_vec())
    }
}
