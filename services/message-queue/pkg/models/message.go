package models

import "time"

type Message struct {
	ID         string                 `json:"id"`
	Type       string                 `json:"type"`
	Payload    map[string]interface{} `json:"payload"`
	Timestamp  time.Time              `json:"timestamp"`
	Priority   int                    `json:"priority"`
	RetryCount int                    `json:"retry_count"`
}

type Queue struct {
	Name        string    `json:"name"`
	MessageCount int       `json:"message_count"`
	Consumers   int       `json:"consumers"`
	CreatedAt   time.Time `json:"created_at"`
}
