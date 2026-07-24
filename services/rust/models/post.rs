use serde::{Deserialize, Serialize};
use chrono::{DateTime, Utc};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Post {
    pub id: Option<i32>,
    pub user_id: i32,
    pub title: String,
    pub content: String,
    pub published: bool,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

impl Post {
    pub fn new(user_id: i32, title: String, content: String) -> Self {
        Self {
            id: None,
            user_id,
            title,
            content,
            published: false,
            created_at: Utc::now(),
            updated_at: Utc::now(),
        }
    }

    pub fn publish(&mut self) {
        self.published = true;
        self.updated_at = Utc::now();
    }

    pub fn unpublish(&mut self) {
        self.published = false;
        self.updated_at = Utc::now();
    }

    pub fn update(&mut self, title: Option<String>, content: Option<String>) {
        if let Some(t) = title {
            self.title = t;
        }
        if let Some(c) = content {
            self.content = c;
        }
        self.updated_at = Utc::now();
    }
}
