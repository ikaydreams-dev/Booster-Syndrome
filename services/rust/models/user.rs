use serde::{Deserialize, Serialize};
use chrono::{DateTime, Utc};
use bcrypt::{hash, verify, DEFAULT_COST};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct User {
    pub id: Option<i32>,
    pub email: String,
    #[serde(skip_serializing)]
    pub password_hash: String,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

impl User {
    pub fn new(email: String, password: &str) -> Result<Self, bcrypt::BcryptError> {
        let password_hash = hash(password, DEFAULT_COST)?;
        
        Ok(Self {
            id: None,
            email,
            password_hash,
            created_at: Utc::now(),
            updated_at: Utc::now(),
        })
    }

    pub fn set_password(&mut self, password: &str) -> Result<(), bcrypt::BcryptError> {
        self.password_hash = hash(password, DEFAULT_COST)?;
        self.updated_at = Utc::now();
        Ok(())
    }

    pub fn verify_password(&self, password: &str) -> Result<bool, bcrypt::BcryptError> {
        verify(password, &self.password_hash)
    }

    pub fn to_public(&self) -> PublicUser {
        PublicUser {
            id: self.id,
            email: self.email.clone(),
            created_at: self.created_at,
            updated_at: self.updated_at,
        }
    }
}

#[derive(Debug, Serialize)]
pub struct PublicUser {
    pub id: Option<i32>,
    pub email: String,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}
