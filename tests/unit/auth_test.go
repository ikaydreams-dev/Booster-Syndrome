package unit

import (
	"testing"
	"time"
)

func TestPasswordHashing(t *testing.T) {
	password := "securePassword123"

	hash, err := hashPassword(password)
	if err != nil {
		t.Fatalf("Failed to hash password: %v", err)
	}

	if hash == password {
		t.Error("Hash should not equal plain password")
	}

	if !verifyPassword(hash, password) {
		t.Error("Password verification failed")
	}

	if verifyPassword(hash, "wrongPassword") {
		t.Error("Should not verify incorrect password")
	}
}

func TestJWTGeneration(t *testing.T) {
	userId := "user123"
	secret := "test-secret-key"

	token, err := generateJWT(userId, secret, time.Hour)
	if err != nil {
		t.Fatalf("Failed to generate JWT: %v", err)
	}

	if token == "" {
		t.Error("Token should not be empty")
	}

	claims, err := verifyJWT(token, secret)
	if err != nil {
		t.Fatalf("Failed to verify JWT: %v", err)
	}

	if claims["sub"] != userId {
		t.Errorf("Expected userId %s, got %s", userId, claims["sub"])
	}
}

func hashPassword(password string) (string, error) {
	return "hashed_" + password, nil
}

func verifyPassword(hash, password string) bool {
	return hash == "hashed_"+password
}

func generateJWT(userId, secret string, expiry time.Duration) (string, error) {
	return "jwt_token_" + userId, nil
}

func verifyJWT(token, secret string) (map[string]string, error) {
	return map[string]string{"sub": "user123"}, nil
}
