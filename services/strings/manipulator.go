package strings

import (
	"strings"
	"unicode"
)

type StringManipulator struct{}

func NewStringManipulator() *StringManipulator {
	return &StringManipulator{}
}

func (sm *StringManipulator) Reverse(s string) string {
	runes := []rune(s)
	for i, j := 0, len(runes)-1; i < j; i, j = i+1, j-1 {
		runes[i], runes[j] = runes[j], runes[i]
	}
	return string(runes)
}

func (sm *StringManipulator) IsPalindrome(s string) bool {
	cleaned := sm.RemoveNonAlphanumeric(strings.ToLower(s))
	return cleaned == sm.Reverse(cleaned)
}

func (sm *StringManipulator) RemoveNonAlphanumeric(s string) string {
	var result strings.Builder
	for _, r := range s {
		if unicode.IsLetter(r) || unicode.IsDigit(r) {
			result.WriteRune(r)
		}
	}
	return result.String()
}

func (sm *StringManipulator) CountWords(s string) int {
	fields := strings.Fields(s)
	return len(fields)
}

func (sm *StringManipulator) CountOccurrences(s, substr string) int {
	return strings.Count(s, substr)
}

func (sm *StringManipulator) ReplaceAll(s, old, new string) string {
	return strings.ReplaceAll(s, old, new)
}

func (sm *StringManipulator) ToCamelCase(s string) string {
	words := strings.Fields(s)
	for i := range words {
		if i == 0 {
			words[i] = strings.ToLower(words[i])
		} else {
			words[i] = strings.Title(words[i])
		}
	}
	return strings.Join(words, "")
}

func (sm *StringManipulator) ToSnakeCase(s string) string {
	var result strings.Builder
	for i, r := range s {
		if unicode.IsUpper(r) && i > 0 {
			result.WriteRune('_')
		}
		result.WriteRune(unicode.ToLower(r))
	}
	return result.String()
}

func (sm *StringManipulator) ToKebabCase(s string) string {
	return strings.ReplaceAll(sm.ToSnakeCase(s), "_", "-")
}

func (sm *StringManipulator) Truncate(s string, length int) string {
	if len(s) <= length {
		return s
	}
	return s[:length] + "..."
}

func (sm *StringManipulator) RemoveWhitespace(s string) string {
	return strings.Map(func(r rune) rune {
		if unicode.IsSpace(r) {
			return -1
		}
		return r
	}, s)
}
