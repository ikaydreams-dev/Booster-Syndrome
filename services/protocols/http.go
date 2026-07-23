package protocols

import (
	"fmt"
	"io"
	"net/http"
	"time"
)

type HTTPClient struct {
	client  *http.Client
	baseURL string
	headers map[string]string
}

func NewHTTPClient(baseURL string, timeout time.Duration) *HTTPClient {
	return &HTTPClient{
		client: &http.Client{
			Timeout: timeout,
		},
		baseURL: baseURL,
		headers: make(map[string]string),
	}
}

func (c *HTTPClient) SetHeader(key, value string) {
	c.headers[key] = value
}

func (c *HTTPClient) RemoveHeader(key string) {
	delete(c.headers, key)
}

func (c *HTTPClient) Get(path string) (*http.Response, error) {
	return c.request(http.MethodGet, path, nil)
}

func (c *HTTPClient) Post(path string, body io.Reader) (*http.Response, error) {
	return c.request(http.MethodPost, path, body)
}

func (c *HTTPClient) Put(path string, body io.Reader) (*http.Response, error) {
	return c.request(http.MethodPut, path, body)
}

func (c *HTTPClient) Patch(path string, body io.Reader) (*http.Response, error) {
	return c.request(http.MethodPatch, path, body)
}

func (c *HTTPClient) Delete(path string) (*http.Response, error) {
	return c.request(http.MethodDelete, path, nil)
}

func (c *HTTPClient) request(method, path string, body io.Reader) (*http.Response, error) {
	url := c.baseURL + path

	req, err := http.NewRequest(method, url, body)
	if err != nil {
		return nil, err
	}

	for key, value := range c.headers {
		req.Header.Set(key, value)
	}

	return c.client.Do(req)
}

type Router struct {
	routes map[string]map[string]http.HandlerFunc
}

func NewRouter() *Router {
	return &Router{
		routes: make(map[string]map[string]http.HandlerFunc),
	}
}

func (r *Router) GET(path string, handler http.HandlerFunc) {
	r.addRoute(http.MethodGet, path, handler)
}

func (r *Router) POST(path string, handler http.HandlerFunc) {
	r.addRoute(http.MethodPost, path, handler)
}

func (r *Router) PUT(path string, handler http.HandlerFunc) {
	r.addRoute(http.MethodPut, path, handler)
}

func (r *Router) PATCH(path string, handler http.HandlerFunc) {
	r.addRoute(http.MethodPatch, path, handler)
}

func (r *Router) DELETE(path string, handler http.HandlerFunc) {
	r.addRoute(http.MethodDelete, path, handler)
}

func (r *Router) addRoute(method, path string, handler http.HandlerFunc) {
	if r.routes[method] == nil {
		r.routes[method] = make(map[string]http.HandlerFunc)
	}
	r.routes[method][path] = handler
}

func (r *Router) ServeHTTP(w http.ResponseWriter, req *http.Request) {
	if methods, ok := r.routes[req.Method]; ok {
		if handler, ok := methods[req.URL.Path]; ok {
			handler(w, req)
			return
		}
	}

	http.NotFound(w, req)
}

type Middleware func(http.HandlerFunc) http.HandlerFunc

func Chain(handler http.HandlerFunc, middlewares ...Middleware) http.HandlerFunc {
	for i := len(middlewares) - 1; i >= 0; i-- {
		handler = middlewares[i](handler)
	}
	return handler
}

func LoggingMiddleware(next http.HandlerFunc) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		start := time.Now()
		next(w, r)
		fmt.Printf("%s %s %v\n", r.Method, r.URL.Path, time.Since(start))
	}
}

func RecoveryMiddleware(next http.HandlerFunc) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		defer func() {
			if err := recover(); err != nil {
				http.Error(w, "Internal Server Error", http.StatusInternalServerError)
				fmt.Printf("Panic: %v\n", err)
			}
		}()
		next(w, r)
	}
}

func CORSMiddleware(next http.HandlerFunc) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Access-Control-Allow-Origin", "*")
		w.Header().Set("Access-Control-Allow-Methods", "GET, POST, PUT, PATCH, DELETE, OPTIONS")
		w.Header().Set("Access-Control-Allow-Headers", "Content-Type, Authorization")

		if r.Method == http.MethodOptions {
			w.WriteHeader(http.StatusOK)
			return
		}

		next(w, r)
	}
}

type RateLimiter struct {
	requests map[string][]time.Time
	limit    int
	window   time.Duration
}

func NewRateLimiter(limit int, window time.Duration) *RateLimiter {
	return &RateLimiter{
		requests: make(map[string][]time.Time),
		limit:    limit,
		window:   window,
	}
}

func (rl *RateLimiter) Allow(key string) bool {
	now := time.Now()
	cutoff := now.Add(-rl.window)

	requests := rl.requests[key]
	filtered := []time.Time{}

	for _, t := range requests {
		if t.After(cutoff) {
			filtered = append(filtered, t)
		}
	}

	if len(filtered) >= rl.limit {
		rl.requests[key] = filtered
		return false
	}

	filtered = append(filtered, now)
	rl.requests[key] = filtered
	return true
}
