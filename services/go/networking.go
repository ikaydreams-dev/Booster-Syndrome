package main

import (
	"bufio"
	"context"
	"crypto/tls"
	"fmt"
	"io"
	"net"
	"net/http"
	"sync"
	"time"
)

type TCPServer struct {
	address  string
	listener net.Listener
	handler  func(net.Conn)
	running  bool
	mu       sync.Mutex
}

func NewTCPServer(address string, handler func(net.Conn)) *TCPServer {
	return &TCPServer{
		address: address,
		handler: handler,
		running: false,
	}
}

func (s *TCPServer) Start() error {
	listener, err := net.Listen("tcp", s.address)
	if err != nil {
		return err
	}

	s.mu.Lock()
	s.listener = listener
	s.running = true
	s.mu.Unlock()

	for s.running {
		conn, err := listener.Accept()
		if err != nil {
			if !s.running {
				break
			}
			continue
		}

		go s.handler(conn)
	}

	return nil
}

func (s *TCPServer) Stop() error {
	s.mu.Lock()
	s.running = false
	s.mu.Unlock()

	if s.listener != nil {
		return s.listener.Close()
	}

	return nil
}

type UDPServer struct {
	address string
	conn    *net.UDPConn
	handler func([]byte, *net.UDPAddr)
	running bool
	mu      sync.Mutex
}

func NewUDPServer(address string, handler func([]byte, *net.UDPAddr)) *UDPServer {
	return &UDPServer{
		address: address,
		handler: handler,
		running: false,
	}
}

func (s *UDPServer) Start() error {
	addr, err := net.ResolveUDPAddr("udp", s.address)
	if err != nil {
		return err
	}

	conn, err := net.ListenUDP("udp", addr)
	if err != nil {
		return err
	}

	s.mu.Lock()
	s.conn = conn
	s.running = true
	s.mu.Unlock()

	buffer := make([]byte, 4096)

	for s.running {
		n, remoteAddr, err := conn.ReadFromUDP(buffer)
		if err != nil {
			if !s.running {
				break
			}
			continue
		}

		data := make([]byte, n)
		copy(data, buffer[:n])

		go s.handler(data, remoteAddr)
	}

	return nil
}

func (s *UDPServer) Stop() error {
	s.mu.Lock()
	s.running = false
	s.mu.Unlock()

	if s.conn != nil {
		return s.conn.Close()
	}

	return nil
}

type HTTPClient struct {
	client  *http.Client
	baseURL string
	headers map[string]string
	mu      sync.RWMutex
}

func NewHTTPClient(baseURL string, timeout time.Duration) *HTTPClient {
	return &HTTPClient{
		client: &http.Client{
			Timeout: timeout,
			Transport: &http.Transport{
				MaxIdleConns:        100,
				MaxIdleConnsPerHost: 10,
				IdleConnTimeout:     90 * time.Second,
			},
		},
		baseURL: baseURL,
		headers: make(map[string]string),
	}
}

func (c *HTTPClient) SetHeader(key, value string) {
	c.mu.Lock()
	defer c.mu.Unlock()
	c.headers[key] = value
}

func (c *HTTPClient) Get(ctx context.Context, path string) (*http.Response, error) {
	req, err := http.NewRequestWithContext(ctx, "GET", c.baseURL+path, nil)
	if err != nil {
		return nil, err
	}

	c.mu.RLock()
	for key, value := range c.headers {
		req.Header.Set(key, value)
	}
	c.mu.RUnlock()

	return c.client.Do(req)
}

func (c *HTTPClient) Post(ctx context.Context, path string, body io.Reader) (*http.Response, error) {
	req, err := http.NewRequestWithContext(ctx, "POST", c.baseURL+path, body)
	if err != nil {
		return nil, err
	}

	c.mu.RLock()
	for key, value := range c.headers {
		req.Header.Set(key, value)
	}
	c.mu.RUnlock()

	return c.client.Do(req)
}

type ConnectionPool struct {
	factory  func() (net.Conn, error)
	pool     chan net.Conn
	maxSize  int
	active   int
	mu       sync.Mutex
	dialFunc func() (net.Conn, error)
}

func NewConnectionPool(maxSize int, dialFunc func() (net.Conn, error)) *ConnectionPool {
	return &ConnectionPool{
		pool:     make(chan net.Conn, maxSize),
		maxSize:  maxSize,
		dialFunc: dialFunc,
	}
}

func (p *ConnectionPool) Get() (net.Conn, error) {
	select {
	case conn := <-p.pool:
		return conn, nil
	default:
		p.mu.Lock()
		if p.active < p.maxSize {
			p.active++
			p.mu.Unlock()
			return p.dialFunc()
		}
		p.mu.Unlock()

		return <-p.pool, nil
	}
}

func (p *ConnectionPool) Put(conn net.Conn) {
	select {
	case p.pool <- conn:
	default:
		conn.Close()
		p.mu.Lock()
		p.active--
		p.mu.Unlock()
	}
}

func (p *ConnectionPool) Close() {
	close(p.pool)
	for conn := range p.pool {
		conn.Close()
	}
}

type WebSocketServer struct {
	upgrader func(http.ResponseWriter, *http.Request) error
	clients  map[*WebSocketClient]bool
	mu       sync.RWMutex
}

type WebSocketClient struct {
	conn     net.Conn
	send     chan []byte
	receive  chan []byte
	server   *WebSocketServer
	isClosed bool
	mu       sync.Mutex
}

func NewWebSocketServer() *WebSocketServer {
	return &WebSocketServer{
		clients: make(map[*WebSocketClient]bool),
	}
}

func (s *WebSocketServer) AddClient(conn net.Conn) *WebSocketClient {
	client := &WebSocketClient{
		conn:    conn,
		send:    make(chan []byte, 256),
		receive: make(chan []byte, 256),
		server:  s,
	}

	s.mu.Lock()
	s.clients[client] = true
	s.mu.Unlock()

	go client.readPump()
	go client.writePump()

	return client
}

func (s *WebSocketServer) RemoveClient(client *WebSocketClient) {
	s.mu.Lock()
	if _, ok := s.clients[client]; ok {
		delete(s.clients, client)
		close(client.send)
	}
	s.mu.Unlock()
}

func (s *WebSocketServer) Broadcast(message []byte) {
	s.mu.RLock()
	defer s.mu.RUnlock()

	for client := range s.clients {
		select {
		case client.send <- message:
		default:
			close(client.send)
			delete(s.clients, client)
		}
	}
}

func (c *WebSocketClient) readPump() {
	defer func() {
		c.server.RemoveClient(c)
		c.conn.Close()
	}()

	reader := bufio.NewReader(c.conn)

	for {
		message, err := reader.ReadBytes('\n')
		if err != nil {
			break
		}

		select {
		case c.receive <- message:
		default:
		}
	}
}

func (c *WebSocketClient) writePump() {
	defer c.conn.Close()

	for message := range c.send {
		_, err := c.conn.Write(message)
		if err != nil {
			break
		}
	}
}

func (c *WebSocketClient) Send(message []byte) {
	c.mu.Lock()
	defer c.mu.Unlock()

	if !c.isClosed {
		select {
		case c.send <- message:
		default:
		}
	}
}

func (c *WebSocketClient) Close() {
	c.mu.Lock()
	defer c.mu.Unlock()

	if !c.isClosed {
		c.isClosed = true
		c.server.RemoveClient(c)
	}
}

type TLSServer struct {
	address  string
	certFile string
	keyFile  string
	listener net.Listener
	handler  func(net.Conn)
	running  bool
	mu       sync.Mutex
}

func NewTLSServer(address, certFile, keyFile string, handler func(net.Conn)) *TLSServer {
	return &TLSServer{
		address:  address,
		certFile: certFile,
		keyFile:  keyFile,
		handler:  handler,
		running:  false,
	}
}

func (s *TLSServer) Start() error {
	cert, err := tls.LoadX509KeyPair(s.certFile, s.keyFile)
	if err != nil {
		return err
	}

	config := &tls.Config{
		Certificates: []tls.Certificate{cert},
	}

	listener, err := tls.Listen("tcp", s.address, config)
	if err != nil {
		return err
	}

	s.mu.Lock()
	s.listener = listener
	s.running = true
	s.mu.Unlock()

	for s.running {
		conn, err := listener.Accept()
		if err != nil {
			if !s.running {
				break
			}
			continue
		}

		go s.handler(conn)
	}

	return nil
}

func (s *TLSServer) Stop() error {
	s.mu.Lock()
	s.running = false
	s.mu.Unlock()

	if s.listener != nil {
		return s.listener.Close()
	}

	return nil
}

type LoadBalancer struct {
	backends []string
	current  int
	mu       sync.Mutex
}

func NewLoadBalancer(backends []string) *LoadBalancer {
	return &LoadBalancer{
		backends: backends,
		current:  0,
	}
}

func (lb *LoadBalancer) NextBackend() string {
	lb.mu.Lock()
	defer lb.mu.Unlock()

	backend := lb.backends[lb.current]
	lb.current = (lb.current + 1) % len(lb.backends)

	return backend
}

type Proxy struct {
	target string
}

func NewProxy(target string) *Proxy {
	return &Proxy{target: target}
}

func (p *Proxy) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	targetURL := fmt.Sprintf("%s%s", p.target, r.URL.Path)

	proxyReq, err := http.NewRequest(r.Method, targetURL, r.Body)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	for key, values := range r.Header {
		for _, value := range values {
			proxyReq.Header.Add(key, value)
		}
	}

	client := &http.Client{Timeout: 30 * time.Second}
	resp, err := client.Do(proxyReq)
	if err != nil {
		http.Error(w, err.Error(), http.StatusBadGateway)
		return
	}
	defer resp.Body.Close()

	for key, values := range resp.Header {
		for _, value := range values {
			w.Header().Add(key, value)
		}
	}

	w.WriteHeader(resp.StatusCode)
	io.Copy(w, resp.Body)
}

type RateLimiter struct {
	rate      int
	interval  time.Duration
	tokens    int
	lastCheck time.Time
	mu        sync.Mutex
}

func NewRateLimiter(rate int, interval time.Duration) *RateLimiter {
	return &RateLimiter{
		rate:      rate,
		interval:  interval,
		tokens:    rate,
		lastCheck: time.Now(),
	}
}

func (rl *RateLimiter) Allow() bool {
	rl.mu.Lock()
	defer rl.mu.Unlock()

	now := time.Now()
	elapsed := now.Sub(rl.lastCheck)

	rl.tokens += int(elapsed / rl.interval)
	if rl.tokens > rl.rate {
		rl.tokens = rl.rate
	}

	rl.lastCheck = now

	if rl.tokens > 0 {
		rl.tokens--
		return true
	}

	return false
}
