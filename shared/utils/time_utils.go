package utils

import "time"

func FormatTimestamp(t time.Time) string {
	return t.Format(time.RFC3339)
}

func ParseTimestamp(s string) (time.Time, error) {
	return time.Parse(time.RFC3339, s)
}

func DaysAgo(days int) time.Time {
	return time.Now().AddDate(0, 0, -days)
}

func IsExpired(t time.Time) bool {
	return time.Now().After(t)
}
