# User Service

TypeScript/Node.js service for user management.

## Features

- User CRUD operations
- Profile management
- MongoDB storage
- Input validation
- Error handling

## Tech Stack

- TypeScript
- Express.js
- MongoDB with Mongoose
- JWT validation

## Running

```bash
# Install dependencies
npm install

# Start development
npm run dev

# Build
npm run build

# Production
npm start
```

## API Endpoints

- GET `/api/v1/users` - List users
- GET `/api/v1/users/:id` - Get user
- PUT `/api/v1/users/:id` - Update user
- DELETE `/api/v1/users/:id` - Delete user

## Testing

```bash
npm test
```
