use serde::{Deserialize, Serialize};
use chrono::{DateTime, Utc};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Comment {
    pub id: Option<i32>,
    pub post_id: i32,
    pub user_id: i32,
    pub content: String,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

impl Comment {
    pub fn new(post_id: i32, user_id: i32, content: String) -> Self {
        Self {
            id: None,
            post_id,
            user_id,
            content,
            created_at: Utc::now(),
            updated_at: Utc::now(),
        }
    }

    pub fn update_content(&mut self, content: String) {
        self.content = content;
        self.updated_at = Utc::now();
    }
}
