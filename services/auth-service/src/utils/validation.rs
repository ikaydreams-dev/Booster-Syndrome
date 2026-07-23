use regex::Regex;
use once_cell::sync::Lazy;

static EMAIL_REGEX: Lazy<Regex> = Lazy::new(|| {
    Regex::new(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$").unwrap()
});

static PASSWORD_REGEX: Lazy<Regex> = Lazy::new(|| {
    Regex::new(r"^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$").unwrap()
});

static USERNAME_REGEX: Lazy<Regex> = Lazy::new(|| {
    Regex::new(r"^[a-zA-Z0-9_-]{3,20}$").unwrap()
});

/// Validates email format
pub fn is_valid_email(email: &str) -> bool {
    EMAIL_REGEX.is_match(email)
}

/// Validates password strength
/// - At least 8 characters
/// - Contains uppercase and lowercase
/// - Contains at least one digit
/// - Contains at least one special character
pub fn is_valid_password(password: &str) -> bool {
    if password.len() < 8 {
        return false;
    }
    PASSWORD_REGEX.is_match(password)
}

/// Validates username format
/// - 3 to 20 characters
/// - Alphanumeric, underscore, and hyphen only
pub fn is_valid_username(username: &str) -> bool {
    USERNAME_REGEX.is_match(username)
}

/// Sanitizes user input to prevent XSS
pub fn sanitize_input(input: &str) -> String {
    input
        .replace('<', "&lt;")
        .replace('>', "&gt;")
        .replace('"', "&quot;")
        .replace('\'', "&#x27;")
        .replace('/', "&#x2F;")
}

/// Validates phone number (simple international format)
pub fn is_valid_phone(phone: &str) -> bool {
    let phone_regex = Regex::new(r"^\+?[1-9]\d{1,14}$").unwrap();
    phone_regex.is_match(phone)
}

/// Checks if a string contains only alphanumeric characters
pub fn is_alphanumeric(s: &str) -> bool {
    s.chars().all(|c| c.is_alphanumeric())
}

/// Validates URL format
pub fn is_valid_url(url: &str) -> bool {
    url.starts_with("http://") || url.starts_with("https://")
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_email_validation() {
        assert!(is_valid_email("test@example.com"));
        assert!(is_valid_email("user.name+tag@example.co.uk"));
        assert!(!is_valid_email("invalid.email"));
        assert!(!is_valid_email("@example.com"));
        assert!(!is_valid_email("test@"));
    }

    #[test]
    fn test_password_validation() {
        assert!(is_valid_password("Test123!@#"));
        assert!(is_valid_password("StrongP@ss1"));
        assert!(!is_valid_password("weak"));
        assert!(!is_valid_password("NoNumbers!"));
        assert!(!is_valid_password("nospecialchar1A"));
    }

    #[test]
    fn test_username_validation() {
        assert!(is_valid_username("user123"));
        assert!(is_valid_username("test-user"));
        assert!(is_valid_username("john_doe"));
        assert!(!is_valid_username("ab"));
        assert!(!is_valid_username("user@name"));
        assert!(!is_valid_username("verylongusernamethatexceedslimit"));
    }

    #[test]
    fn test_sanitize_input() {
        assert_eq!(sanitize_input("<script>alert('xss')</script>"),
                   "&lt;script&gt;alert(&#x27;xss&#x27;)&lt;&#x2F;script&gt;");
        assert_eq!(sanitize_input("Safe input"), "Safe input");
    }

    #[test]
    fn test_phone_validation() {
        assert!(is_valid_phone("+14155552671"));
        assert!(is_valid_phone("14155552671"));
        assert!(!is_valid_phone("123"));
        assert!(!is_valid_phone("not-a-phone"));
    }
}
