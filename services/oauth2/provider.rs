use chrono::{Duration, Utc};
use jsonwebtoken::{encode, decode, Header, Validation, EncodingKey, DecodingKey, Algorithm};
use serde::{Deserialize, Serialize};
use sha2::{Sha256, Digest};
use rand::Rng;

#[derive(Debug, Serialize, Deserialize)]
pub struct OAuth2TokenClaims {
    pub sub: String,
    pub client_id: String,
    pub scope: Vec<String>,
    pub exp: i64,
    pub iat: i64,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct AuthorizationCode {
    pub code: String,
    pub client_id: String,
    pub user_id: String,
    pub redirect_uri: String,
    pub scope: Vec<String>,
    pub expires_at: i64,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct AccessToken {
    pub access_token: String,
    pub token_type: String,
    pub expires_in: i64,
    pub refresh_token: Option<String>,
    pub scope: String,
}

pub struct OAuth2Provider {
    secret_key: String,
}

impl OAuth2Provider {
    pub fn new(secret_key: String) -> Self {
        OAuth2Provider { secret_key }
    }

    pub fn generate_authorization_code(
        &self,
        client_id: &str,
        user_id: &str,
        redirect_uri: &str,
        scope: Vec<String>,
    ) -> AuthorizationCode {
        let code = self.generate_random_string(32);
        let expires_at = Utc::now() + Duration::minutes(10);

        AuthorizationCode {
            code,
            client_id: client_id.to_string(),
            user_id: user_id.to_string(),
            redirect_uri: redirect_uri.to_string(),
            scope,
            expires_at: expires_at.timestamp(),
        }
    }

    pub fn exchange_code_for_token(
        &self,
        auth_code: &AuthorizationCode,
    ) -> Result<AccessToken, String> {
        if Utc::now().timestamp() > auth_code.expires_at {
            return Err("Authorization code expired".to_string());
        }

        let claims = OAuth2TokenClaims {
            sub: auth_code.user_id.clone(),
            client_id: auth_code.client_id.clone(),
            scope: auth_code.scope.clone(),
            exp: (Utc::now() + Duration::hours(1)).timestamp(),
            iat: Utc::now().timestamp(),
        };

        let token = encode(
            &Header::default(),
            &claims,
            &EncodingKey::from_secret(self.secret_key.as_bytes()),
        )
        .map_err(|e| e.to_string())?;

        let refresh_token = self.generate_random_string(64);

        Ok(AccessToken {
            access_token: token,
            token_type: "Bearer".to_string(),
            expires_in: 3600,
            refresh_token: Some(refresh_token),
            scope: auth_code.scope.join(" "),
        })
    }

    pub fn verify_token(&self, token: &str) -> Result<OAuth2TokenClaims, String> {
        decode::<OAuth2TokenClaims>(
            token,
            &DecodingKey::from_secret(self.secret_key.as_bytes()),
            &Validation::new(Algorithm::HS256),
        )
        .map(|data| data.claims)
        .map_err(|e| e.to_string())
    }

    fn generate_random_string(&self, length: usize) -> String {
        let mut rng = rand::thread_rng();
        let chars: Vec<char> = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
            .chars()
            .collect();

        (0..length)
            .map(|_| chars[rng.gen_range(0..chars.len())])
            .collect()
    }
}
