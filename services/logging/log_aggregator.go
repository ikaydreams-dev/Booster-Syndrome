package logging

import (
	"encoding/json"
	"time"
)

type LogLevel string

const (
	DEBUG   LogLevel = "DEBUG"
	INFO    LogLevel = "INFO"
	WARNING LogLevel = "WARNING"
	ERROR   LogLevel = "ERROR"
	FATAL   LogLevel = "FATAL"
)

type LogEntry struct {
	Timestamp string                 `json:"timestamp"`
	Level     LogLevel               `json:"level"`
	Service   string                 `json:"service"`
	Message   string                 `json:"message"`
	Context   map[string]interface{} `json:"context,omitempty"`
}

type LogAggregator struct {
	logs []LogEntry
}

func NewLogAggregator() *LogAggregator {
	return &LogAggregator{
		logs: make([]LogEntry, 0),
	}
}

func (la *LogAggregator) Log(level LogLevel, service, message string, context map[string]interface{}) {
	entry := LogEntry{
		Timestamp: time.Now().Format(time.RFC3339),
		Level:     level,
		Service:   service,
		Message:   message,
		Context:   context,
	}

	la.logs = append(la.logs, entry)
}

func (la *LogAggregator) Debug(service, message string) {
	la.Log(DEBUG, service, message, nil)
}

func (la *LogAggregator) Info(service, message string) {
	la.Log(INFO, service, message, nil)
}

func (la *LogAggregator) Error(service, message string, err error) {
	context := map[string]interface{}{}
	if err != nil {
		context["error"] = err.Error()
	}
	la.Log(ERROR, service, message, context)
}

func (la *LogAggregator) GetLogs() []LogEntry {
	return la.logs
}

func (la *LogAggregator) ExportJSON() (string, error) {
	data, err := json.Marshal(la.logs)
	if err != nil {
		return "", err
	}
	return string(data), nil
}
