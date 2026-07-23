package utils

import (
	"regexp"
	"strings"
)

var (
	emailRegex    = regexp.MustCompile(`^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$`)
	usernameRegex = regexp.MustCompile(`^[a-zA-Z0-9_-]{3,20}$`)
)

func IsValidEmail(email string) bool {
	return emailRegex.MatchString(email)
}

func IsValidUsername(username string) bool {
	return usernameRegex.MatchString(username)
}

func IsValidPassword(password string) bool {
	return len(password) >= 8
}

func IsEmpty(s string) bool {
	return strings.TrimSpace(s) == ""
}
