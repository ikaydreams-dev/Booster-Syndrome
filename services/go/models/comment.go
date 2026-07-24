package models

import "time"

type Comment struct {
	ID        int       `json:"id"`
	PostID    int       `json:"post_id"`
	UserID    int       `json:"user_id"`
	Content   string    `json:"content"`
	CreatedAt time.Time `json:"created_at"`
	UpdatedAt time.Time `json:"updated_at"`
}

func NewComment(postID, userID int, content string) *Comment {
	return &Comment{
		PostID:    postID,
		UserID:    userID,
		Content:   content,
		CreatedAt: time.Now(),
		UpdatedAt: time.Now(),
	}
}

func (c *Comment) Update(content string) {
	c.Content = content
	c.UpdatedAt = time.Now()
}

func (c *Comment) ToMap() map[string]interface{} {
	return map[string]interface{}{
		"id":         c.ID,
		"post_id":    c.PostID,
		"user_id":    c.UserID,
		"content":    c.Content,
		"created_at": c.CreatedAt,
		"updated_at": c.UpdatedAt,
	}
}
