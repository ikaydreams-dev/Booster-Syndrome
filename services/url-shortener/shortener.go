package urlshortener

import (
	"crypto/md5"
	"encoding/hex"
	"sync"
)

type URLShortener struct {
	urls map[string]string
	mu   sync.RWMutex
}

func NewURLShortener() *URLShortener {
	return &URLShortener{
		urls: make(map[string]string),
	}
}

func (us *URLShortener) Shorten(longURL string) string {
	us.mu.Lock()
	defer us.mu.Unlock()

	hash := md5.Sum([]byte(longURL))
	shortCode := hex.EncodeToString(hash[:])[:8]

	us.urls[shortCode] = longURL

	return shortCode
}

func (us *URLShortener) Resolve(shortCode string) (string, bool) {
	us.mu.RLock()
	defer us.mu.RUnlock()

	longURL, exists := us.urls[shortCode]
	return longURL, exists
}

func (us *URLShortener) Delete(shortCode string) {
	us.mu.Lock()
	defer us.mu.Unlock()

	delete(us.urls, shortCode)
}

func (us *URLShortener) GetStats() map[string]interface{} {
	us.mu.RLock()
	defer us.mu.RUnlock()

	return map[string]interface{}{
		"total_urls": len(us.urls),
	}
}
