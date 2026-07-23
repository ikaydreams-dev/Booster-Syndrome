use std::sync::Arc;
use std::collections::HashMap;
use std::time::{Duration, Instant};
use tokio::sync::Mutex;

pub struct RateLimiter {
    requests: Arc<Mutex<HashMap<String, Vec<Instant>>>>,
    max_requests: usize,
    window: Duration,
}

impl RateLimiter {
    pub fn new(max_requests: usize, window_secs: u64) -> Self {
        Self {
            requests: Arc::new(Mutex::new(HashMap::new())),
            max_requests,
            window: Duration::from_secs(window_secs),
        }
    }

    pub async fn check_rate_limit(&self, key: &str) -> bool {
        let mut requests = self.requests.lock().await;
        let now = Instant::now();

        let user_requests = requests.entry(key.to_string()).or_insert_with(Vec::new);

        user_requests.retain(|&timestamp| now.duration_since(timestamp) < self.window);

        if user_requests.len() >= self.max_requests {
            return false;
        }

        user_requests.push(now);
        true
    }
}
