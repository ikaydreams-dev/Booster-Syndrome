package logging

import (
	"fmt"
	"log"
	"os"
	"runtime"
	"strings"
	"time"
)

type LogLevel int

const (
	DEBUG LogLevel = iota
	INFO
	WARNING
	ERROR
	FATAL
)

func (l LogLevel) String() string {
	return [...]string{"DEBUG", "INFO", "WARNING", "ERROR", "FATAL"}[l]
}

type Logger struct {
	level      LogLevel
	serviceName string
	output     *os.File
}

func NewLogger(serviceName string, level LogLevel) *Logger {
	return &Logger{
		level:       level,
		serviceName: serviceName,
		output:      os.Stdout,
	}
}

func (l *Logger) log(level LogLevel, message string, fields map[string]interface{}) {
	if level < l.level {
		return
	}

	timestamp := time.Now().UTC().Format(time.RFC3339)

	_, file, line, _ := runtime.Caller(2)
	shortFile := file[strings.LastIndex(file, "/")+1:]

	fieldsStr := ""
	if len(fields) > 0 {
		parts := make([]string, 0, len(fields))
		for k, v := range fields {
			parts = append(parts, fmt.Sprintf("%s=%v", k, v))
		}
		fieldsStr = " " + strings.Join(parts, " ")
	}

	logLine := fmt.Sprintf("[%s] %s %s:%d [%s] %s%s\n",
		timestamp,
		level.String(),
		shortFile,
		line,
		l.serviceName,
		message,
		fieldsStr,
	)

	log.Print(logLine)
}

func (l *Logger) Debug(message string, fields ...map[string]interface{}) {
	f := make(map[string]interface{})
	if len(fields) > 0 {
		f = fields[0]
	}
	l.log(DEBUG, message, f)
}

func (l *Logger) Info(message string, fields ...map[string]interface{}) {
	f := make(map[string]interface{})
	if len(fields) > 0 {
		f = fields[0]
	}
	l.log(INFO, message, f)
}

func (l *Logger) Warning(message string, fields ...map[string]interface{}) {
	f := make(map[string]interface{})
	if len(fields) > 0 {
		f = fields[0]
	}
	l.log(WARNING, message, f)
}

func (l *Logger) Error(message string, fields ...map[string]interface{}) {
	f := make(map[string]interface{})
	if len(fields) > 0 {
		f = fields[0]
	}
	l.log(ERROR, message, f)
}

func (l *Logger) Fatal(message string, fields ...map[string]interface{}) {
	f := make(map[string]interface{})
	if len(fields) > 0 {
		f = fields[0]
	}
	l.log(FATAL, message, f)
	os.Exit(1)
}

var defaultLogger = NewLogger("default", INFO)

func Debug(message string, fields ...map[string]interface{}) {
	defaultLogger.Debug(message, fields...)
}

func Info(message string, fields ...map[string]interface{}) {
	defaultLogger.Info(message, fields...)
}

func Warning(message string, fields ...map[string]interface{}) {
	defaultLogger.Warning(message, fields...)
}

func Error(message string, fields ...map[string]interface{}) {
	defaultLogger.Error(message, fields...)
}

func Fatal(message string, fields ...map[string]interface{}) {
	defaultLogger.Fatal(message, fields...)
}
