package serializers

import (
	"encoding/json"
	"time"
)

type UserResponse struct {
	ID        int       `json:"id"`
	Email     string    `json:"email"`
	CreatedAt time.Time `json:"created_at"`
	UpdatedAt time.Time `json:"updated_at"`
}

type PostResponse struct {
	ID        int       `json:"id"`
	UserID    int       `json:"user_id"`
	Title     string    `json:"title"`
	Content   string    `json:"content"`
	Published bool      `json:"published"`
	CreatedAt time.Time `json:"created_at"`
	UpdatedAt time.Time `json:"updated_at"`
}

type CommentResponse struct {
	ID        int       `json:"id"`
	PostID    int       `json:"post_id"`
	UserID    int       `json:"user_id"`
	Content   string    `json:"content"`
	CreatedAt time.Time `json:"created_at"`
	UpdatedAt time.Time `json:"updated_at"`
}

type PaginatedResponse struct {
	Data       interface{} `json:"data"`
	Pagination Pagination  `json:"pagination"`
}

type Pagination struct {
	Page       int `json:"page"`
	PerPage    int `json:"per_page"`
	Total      int `json:"total"`
	TotalPages int `json:"total_pages"`
}

type ErrorResponse struct {
	Error   string            `json:"error"`
	Message string            `json:"message,omitempty"`
	Details map[string]string `json:"details,omitempty"`
}

func SerializeUser(user interface{}) ([]byte, error) {
	return json.Marshal(user)
}

func SerializePost(post interface{}) ([]byte, error) {
	return json.Marshal(post)
}

func SerializePaginated(data interface{}, pagination Pagination) ([]byte, error) {
	response := PaginatedResponse{
		Data:       data,
		Pagination: pagination,
	}
	return json.Marshal(response)
}

func SerializeError(err error, message string) ([]byte, error) {
	response := ErrorResponse{
		Error:   err.Error(),
		Message: message,
	}
	return json.Marshal(response)
}
