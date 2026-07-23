package webhooks

import (
	"bytes"
	"context"
	"crypto/hmac"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"net/http"
	"time"
)

type Webhook struct {
	ID        string            `json:"id"`
	URL       string            `json:"url"`
	Events    []string          `json:"events"`
	Secret    string            `json:"secret"`
	Active    bool              `json:"active"`
	Headers   map[string]string `json:"headers"`
	CreatedAt time.Time         `json:"createdAt"`
}

type WebhookPayload struct {
	Event     string                 `json:"event"`
	Data      map[string]interface{} `json:"data"`
	Timestamp time.Time              `json:"timestamp"`
}

type WebhookDelivery struct {
	ID         string    `json:"id"`
	WebhookID  string    `json:"webhookId"`
	Payload    string    `json:"payload"`
	StatusCode int       `json:"statusCode"`
	Response   string    `json:"response"`
	Attempts   int       `json:"attempts"`
	Success    bool      `json:"success"`
	CreatedAt  time.Time `json:"createdAt"`
}

type WebhookService struct {
	client     *http.Client
	maxRetries int
}

func NewWebhookService(maxRetries int) *WebhookService {
	return &WebhookService{
		client: &http.Client{
			Timeout: 30 * time.Second,
		},
		maxRetries: maxRetries,
	}
}

func (s *WebhookService) Deliver(ctx context.Context, webhook *Webhook, payload *WebhookPayload) (*WebhookDelivery, error) {
	delivery := &WebhookDelivery{
		ID:        generateID(),
		WebhookID: webhook.ID,
		CreatedAt: time.Now(),
	}

	payloadBytes, err := json.Marshal(payload)
	if err != nil {
		return delivery, err
	}

	delivery.Payload = string(payloadBytes)

	for attempt := 1; attempt <= s.maxRetries; attempt++ {
		delivery.Attempts = attempt

		statusCode, response, err := s.sendRequest(ctx, webhook, payloadBytes)

		delivery.StatusCode = statusCode
		delivery.Response = response

		if err == nil && statusCode >= 200 && statusCode < 300 {
			delivery.Success = true
			return delivery, nil
		}

		if attempt < s.maxRetries {
			backoff := time.Duration(attempt*attempt) * time.Second
			time.Sleep(backoff)
		}
	}

	return delivery, nil
}

func (s *WebhookService) sendRequest(ctx context.Context, webhook *Webhook, payload []byte) (int, string, error) {
	req, err := http.NewRequestWithContext(ctx, "POST", webhook.URL, bytes.NewReader(payload))
	if err != nil {
		return 0, "", err
	}

	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("User-Agent", "Booster-Webhook/1.0")

	signature := generateSignature(payload, webhook.Secret)
	req.Header.Set("X-Webhook-Signature", signature)
	req.Header.Set("X-Webhook-Timestamp", time.Now().Format(time.RFC3339))

	for key, value := range webhook.Headers {
		req.Header.Set(key, value)
	}

	resp, err := s.client.Do(req)
	if err != nil {
		return 0, "", err
	}
	defer resp.Body.Close()

	buf := new(bytes.Buffer)
	buf.ReadFrom(resp.Body)

	return resp.StatusCode, buf.String(), nil
}

func generateSignature(payload []byte, secret string) string {
	h := hmac.New(sha256.New, []byte(secret))
	h.Write(payload)
	return hex.EncodeToString(h.Sum(nil))
}

func VerifySignature(payload []byte, secret, signature string) bool {
	expected := generateSignature(payload, secret)
	return hmac.Equal([]byte(expected), []byte(signature))
}

func generateID() string {
	return time.Now().Format("20060102150405")
}
