package utils

import (
	"fmt"
	"os"
	"time"

	"github.com/sirupsen/logrus"
)

var log = logrus.New()

func init() {
	// Set log format
	log.SetFormatter(&logrus.JSONFormatter{
		TimestampFormat: time.RFC3339,
	})

	// Set log level
	level := os.Getenv("LOG_LEVEL")
	switch level {
	case "debug":
		log.SetLevel(logrus.DebugLevel)
	case "info":
		log.SetLevel(logrus.InfoLevel)
	case "warn":
		log.SetLevel(logrus.WarnLevel)
	case "error":
		log.SetLevel(logrus.ErrorLevel)
	default:
		log.SetLevel(logrus.InfoLevel)
	}

	// Output to stdout
	log.SetOutput(os.Stdout)
}

// Logger returns the configured logger instance
func Logger() *logrus.Logger {
	return log
}

// Info logs an info message
func Info(message string, fields map[string]interface{}) {
	log.WithFields(fields).Info(message)
}

// Debug logs a debug message
func Debug(message string, fields map[string]interface{}) {
	log.WithFields(fields).Debug(message)
}

// Warn logs a warning message
func Warn(message string, fields map[string]interface{}) {
	log.WithFields(fields).Warn(message)
}

// Error logs an error message
func Error(message string, err error, fields map[string]interface{}) {
	if fields == nil {
		fields = make(map[string]interface{})
	}
	if err != nil {
		fields["error"] = err.Error()
	}
	log.WithFields(fields).Error(message)
}

// Fatal logs a fatal message and exits
func Fatal(message string, err error) {
	log.WithFields(logrus.Fields{
		"error": err.Error(),
	}).Fatal(message)
}

// RequestLogger logs HTTP request details
func RequestLogger(method, path string, statusCode int, duration time.Duration) {
	log.WithFields(logrus.Fields{
		"method":      method,
		"path":        path,
		"status_code": statusCode,
		"duration_ms": duration.Milliseconds(),
	}).Info("HTTP request")
}

// StructuredLog creates a structured log entry
type StructuredLog struct {
	fields logrus.Fields
}

// NewStructuredLog creates a new structured log
func NewStructuredLog() *StructuredLog {
	return &StructuredLog{
		fields: make(logrus.Fields),
	}
}

// AddField adds a field to the log
func (s *StructuredLog) AddField(key string, value interface{}) *StructuredLog {
	s.fields[key] = value
	return s
}

// Info logs at info level
func (s *StructuredLog) Info(message string) {
	log.WithFields(s.fields).Info(message)
}

// Error logs at error level
func (s *StructuredLog) Error(message string) {
	log.WithFields(s.fields).Error(message)
}

// Warn logs at warn level
func (s *StructuredLog) Warn(message string) {
	log.WithFields(s.fields).Warn(message)
}

// Debug logs at debug level
func (s *StructuredLog) Debug(message string) {
	log.WithFields(s.fields).Debug(message)
}
