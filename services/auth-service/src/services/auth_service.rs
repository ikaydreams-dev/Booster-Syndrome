use anyhow::{Result, anyhow};
use sqlx::PgPool;
use uuid::Uuid;

use crate::models::{RegisterRequest, LoginRequest, User, TokenResponse};
use super::{password_service, token_service};

pub async fn register_user(
    pool: &PgPool,
    req: RegisterRequest,
) -> Result<(User, TokenResponse)> {
    let existing = sqlx::query_as::<_, User>(
        "SELECT * FROM users WHERE email = $1 OR username = $2"
    )
    .bind(&req.email)
    .bind(&req.username)
    .fetch_optional(pool)
    .await?;

    if existing.is_some() {
        return Err(anyhow!("User already exists"));
    }

    let password_hash = password_service::hash_password(&req.password)?;
    let user_id = Uuid::new_v4();

    let user = sqlx::query_as::<_, User>(
        "INSERT INTO users (id, email, password_hash, username)
         VALUES ($1, $2, $3, $4)
         RETURNING *"
    )
    .bind(user_id)
    .bind(&req.email)
    .bind(&password_hash)
    .bind(&req.username)
    .fetch_one(pool)
    .await?;

    let tokens = token_service::generate_tokens(user.id, &user.email)?;

    Ok((user, tokens))
}

pub async fn login_user(
    pool: &PgPool,
    req: LoginRequest,
) -> Result<(User, TokenResponse)> {
    let user = sqlx::query_as::<_, User>("SELECT * FROM users WHERE email = $1")
        .bind(&req.email)
        .fetch_optional(pool)
        .await?
        .ok_or_else(|| anyhow!("Invalid credentials"))?;

    if !password_service::verify_password(&req.password, &user.password_hash)? {
        return Err(anyhow!("Invalid credentials"));
    }

    if !user.is_active {
        return Err(anyhow!("Account is inactive"));
    }

    let tokens = token_service::generate_tokens(user.id, &user.email)?;

    Ok((user, tokens))
}

pub async fn refresh_access_token(
    pool: &PgPool,
    refresh_token: &str,
) -> Result<TokenResponse> {
    let claims = token_service::verify_refresh_token(refresh_token)?;

    let user = sqlx::query_as::<_, User>("SELECT * FROM users WHERE id = $1")
        .bind(claims.sub)
        .fetch_optional(pool)
        .await?
        .ok_or_else(|| anyhow!("User not found"))?;

    token_service::generate_tokens(user.id, &user.email)
}

pub async fn logout_user(pool: &PgPool, refresh_token: &str) -> Result<()> {
    Ok(())
}
