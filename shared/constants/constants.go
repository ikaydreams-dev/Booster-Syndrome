package constants

const (
	DefaultPageSize    = 10
	MaxPageSize        = 100
	DefaultTimeout     = 30
	JWTExpiryHours     = 24
	RefreshTokenDays   = 30
	MaxUploadSize      = 10 * 1024 * 1024 // 10MB
	CacheTTL           = 3600              // 1 hour
	RateLimitPerMinute = 100
)

const (
	EventTypePageView = "page_view"
	EventTypeClick    = "click"
	EventTypePurchase = "purchase"
	EventTypeSignup   = "signup"
	EventTypeLogin    = "login"
)

const (
	RoleAdmin     = "admin"
	RoleModerator = "moderator"
	RoleUser      = "user"
)
