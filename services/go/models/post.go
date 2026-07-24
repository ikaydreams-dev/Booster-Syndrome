package models

import "time"

type Post struct {
	ID        int       `json:"id"`
	UserID    int       `json:"user_id"`
	Title     string    `json:"title"`
	Content   string    `json:"content"`
	Published bool      `json:"published"`
	CreatedAt time.Time `json:"created_at"`
	UpdatedAt time.Time `json:"updated_at"`
}

func NewPost(userID int, title, content string) *Post {
	return &Post{
		UserID:    userID,
		Title:     title,
		Content:   content,
		Published: false,
		CreatedAt: time.Now(),
		UpdatedAt: time.Now(),
	}
}

func (p *Post) Publish() {
	p.Published = true
	p.UpdatedAt = time.Now()
}

func (p *Post) Unpublish() {
	p.Published = false
	p.UpdatedAt = time.Now()
}

func (p *Post) Update(title, content string) {
	if title != "" {
		p.Title = title
	}
	if content != "" {
		p.Content = content
	}
	p.UpdatedAt = time.Now()
}

func (p *Post) ToMap() map[string]interface{} {
	return map[string]interface{}{
		"id":         p.ID,
		"user_id":    p.UserID,
		"title":      p.Title,
		"content":    p.Content,
		"published":  p.Published,
		"created_at": p.CreatedAt,
		"updated_at": p.UpdatedAt,
	}
}
