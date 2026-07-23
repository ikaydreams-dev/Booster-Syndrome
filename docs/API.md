# API Documentation

## Base URL
```
http://localhost:8000/api/v1
```

## Authentication

All protected endpoints require a JWT token in the Authorization header:
```
Authorization: Bearer <token>
```

## Endpoints

### Auth Service

#### Register
```http
POST /auth/register
Content-Type: application/json

{
  "email": "user@example.com",
  "username": "username",
  "password": "password123"
}
```

Response:
```json
{
  "user": {
    "id": "uuid",
    "email": "user@example.com",
    "username": "username"
  },
  "tokens": {
    "access_token": "jwt_token",
    "refresh_token": "refresh_token",
    "token_type": "Bearer",
    "expires_in": 3600
  }
}
```

#### Login
```http
POST /auth/login
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "password123"
}
```

#### Refresh Token
```http
POST /auth/refresh
Content-Type: application/json

{
  "refresh_token": "refresh_token"
}
```

### User Service

#### Get User
```http
GET /users/:id
Authorization: Bearer <token>
```

#### Update User
```http
PUT /users/:id
Authorization: Bearer <token>
Content-Type: application/json

{
  "firstName": "John",
  "lastName": "Doe",
  "bio": "Software developer"
}
```

#### List Users
```http
GET /users?page=1&limit=10
Authorization: Bearer <token>
```

### Analytics Service

#### Track Event
```http
POST /analytics/events
Authorization: Bearer <token>
Content-Type: application/json

{
  "user_id": "uuid",
  "event_type": "click",
  "event_name": "button_click",
  "properties": {
    "button_id": "submit"
  }
}
```

#### Get Stats
```http
GET /stats/summary
Authorization: Bearer <token>
```

#### Daily Stats
```http
GET /stats/daily?days=7
Authorization: Bearer <token>
```

### File Service

#### Upload File
```http
POST /files/upload
Authorization: Bearer <token>
Content-Type: multipart/form-data

file: <binary>
```

#### Get File
```http
GET /files/:id
Authorization: Bearer <token>
```

#### Delete File
```http
DELETE /files/:id
Authorization: Bearer <token>
```

### Notification Service

#### Send Email
```http
POST /notifications/email
Authorization: Bearer <token>
Content-Type: application/json

{
  "to": "recipient@example.com",
  "subject": "Test Email",
  "body": "Email content"
}
```

## Error Responses

All endpoints may return these error codes:

- `400 Bad Request` - Invalid input
- `401 Unauthorized` - Missing or invalid token
- `403 Forbidden` - Insufficient permissions
- `404 Not Found` - Resource not found
- `429 Too Many Requests` - Rate limit exceeded
- `500 Internal Server Error` - Server error

Error format:
```json
{
  "error": "Error message",
  "details": "Additional details"
}
```
