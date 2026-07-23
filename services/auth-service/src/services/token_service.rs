use anyhow::Result;
use chrono::Utc;
use jsonwebtoken::{encode, decode, Header, Validation, EncodingKey, DecodingKey};
use uuid::Uuid;

use crate::models::{Claims, TokenResponse};

const ACCESS_TOKEN_EXPIRY: i64 = 3600;
const REFRESH_TOKEN_EXPIRY: i64 = 2592000;

fn get_jwt_secret() -> String {
    std::env::var("JWT_SECRET").unwrap_or_else(|_| "super-secret-key".to_string())
}

pub fn generate_tokens(user_id: Uuid, email: &str) -> Result<TokenResponse> {
    let now = Utc::now().timestamp();

    let access_claims = Claims {
        sub: user_id,
        email: email.to_string(),
        exp: now + ACCESS_TOKEN_EXPIRY,
        iat: now,
    };

    let refresh_claims = Claims {
        sub: user_id,
        email: email.to_string(),
        exp: now + REFRESH_TOKEN_EXPIRY,
        iat: now,
    };

    let secret = get_jwt_secret();
    let encoding_key = EncodingKey::from_secret(secret.as_bytes());

    let access_token = encode(&Header::default(), &access_claims, &encoding_key)?;
    let refresh_token = encode(&Header::default(), &refresh_claims, &encoding_key)?;

    Ok(TokenResponse {
        access_token,
        refresh_token,
        token_type: "Bearer".to_string(),
        expires_in: ACCESS_TOKEN_EXPIRY,
    })
}

pub fn verify_access_token(token: &str) -> Result<Claims> {
    let secret = get_jwt_secret();
    let decoding_key = DecodingKey::from_secret(secret.as_bytes());

    let token_data = decode::<Claims>(token, &decoding_key, &Validation::default())?;
    Ok(token_data.claims)
}

pub fn verify_refresh_token(token: &str) -> Result<Claims> {
    let secret = get_jwt_secret();
    let decoding_key = DecodingKey::from_secret(secret.as_bytes());

    let token_data = decode::<Claims>(token, &decoding_key, &Validation::default())?;
    Ok(token_data.claims)
}
