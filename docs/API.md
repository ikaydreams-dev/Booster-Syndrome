# API Documentation

## Authentication Endpoints

### POST /auth/register
Register a new user.

**Request:**
```json
{
  "email": "user@example.com",
  "password": "secure_password"
}
```

**Response:**
```json
{
  "id": 1,
  "email": "user@example.com",
  "token": "jwt_token_here"
}
```

### POST /auth/login
Authenticate and receive a token.

**Request:**
```json
{
  "email": "user@example.com",
  "password": "secure_password"
}
```

**Response:**
```json
{
  "token": "jwt_token_here",
  "expires_in": 3600
}
```

### POST /auth/refresh
Refresh an expired token.

**Headers:**
```
Authorization: Bearer <token>
```

**Response:**
```json
{
  "token": "new_jwt_token",
  "expires_in": 3600
}
```

## User Endpoints

### GET /users/me
Get current user profile.

**Headers:**
```
Authorization: Bearer <token>
```

**Response:**
```json
{
  "id": 1,
  "email": "user@example.com",
  "created_at": "2024-01-01T00:00:00Z"
}
```
