# Testing Guide

## Running Tests

### All Tests
```bash
make test
# or
./scripts/test-all.sh
```

### Individual Services

#### Auth Service (Rust)
```bash
cd services/auth-service
cargo test
cargo test -- --nocapture  # with output
```

#### Gateway (Go)
```bash
cd services/gateway
go test ./...
go test -v ./...  # verbose
go test -cover ./...  # with coverage
```

#### User Service (TypeScript)
```bash
cd services/user-service
npm test
npm test -- --coverage
```

#### Analytics Service (Python)
```bash
cd services/analytics-service
pytest
pytest --cov=app  # with coverage
pytest -v  # verbose
```

## Unit Tests

Unit tests should test individual functions/methods in isolation.

### Example (TypeScript)
```typescript
describe('UserService', () => {
  it('should create a user', async () => {
    const user = await userService.create({
      email: 'test@example.com',
      username: 'testuser'
    });
    expect(user.email).toBe('test@example.com');
  });
});
```

## Integration Tests

Integration tests verify that services work together correctly.

### Example (Rust)
```rust
#[tokio::test]
async fn test_login_flow() {
    let response = login_user(&pool, credentials).await;
    assert!(response.is_ok());
}
```

## End-to-End Tests

E2E tests verify complete workflows.

```bash
cd web/frontend
npm run test:e2e
```

## Test Coverage

Generate coverage reports:

```bash
# Rust
cargo tarpaulin --out Html

# Go
go test -coverprofile=coverage.out ./...
go tool cover -html=coverage.out

# TypeScript
npm test -- --coverage

# Python
pytest --cov=app --cov-report=html
```

## Continuous Integration

Tests run automatically on every push via GitHub Actions.

See `.github/workflows/ci.yml` for configuration.

## Writing Tests

### Best Practices

1. **Arrange-Act-Assert** pattern
2. **One assertion per test**
3. **Meaningful test names**
4. **Clean up after tests**
5. **Use fixtures and mocks**

### Test Data

Use realistic but non-sensitive test data:
```json
{
  "email": "test@example.com",
  "username": "testuser",
  "password": "Test123!@#"
}
```

## Debugging Tests

### Rust
```bash
RUST_LOG=debug cargo test -- --nocapture
```

### Go
```bash
go test -v -run TestName
```

### TypeScript
```bash
npm test -- --debug
```

### Python
```bash
pytest -s --log-cli-level=DEBUG
```
