package integration

import (
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
)

func TestUserRegistration(t *testing.T) {
	payload := `{"email":"test@example.com","username":"testuser","password":"password123"}`

	req := httptest.NewRequest("POST", "/api/auth/register", strings.NewReader(payload))
	req.Header.Set("Content-Type", "application/json")

	w := httptest.NewRecorder()

	if w.Code != http.StatusCreated {
		t.Errorf("Expected status %d, got %d", http.StatusCreated, w.Code)
	}
}

func TestUserLogin(t *testing.T) {
	payload := `{"email":"test@example.com","password":"password123"}`

	req := httptest.NewRequest("POST", "/api/auth/login", strings.NewReader(payload))
	req.Header.Set("Content-Type", "application/json")

	w := httptest.NewRecorder()

	if w.Code != http.StatusOK {
		t.Errorf("Expected status %d, got %d", http.StatusOK, w.Code)
	}
}

func TestGetUserProfile(t *testing.T) {
	req := httptest.NewRequest("GET", "/api/users/me", nil)
	req.Header.Set("Authorization", "Bearer test_token")

	w := httptest.NewRecorder()

	if w.Code != http.StatusOK {
		t.Errorf("Expected status %d, got %d", http.StatusOK, w.Code)
	}
}

func TestUnauthorizedAccess(t *testing.T) {
	req := httptest.NewRequest("GET", "/api/users/me", nil)

	w := httptest.NewRecorder()

	if w.Code != http.StatusUnauthorized {
		t.Errorf("Expected status %d, got %d", http.StatusUnauthorized, w.Code)
	}
}
