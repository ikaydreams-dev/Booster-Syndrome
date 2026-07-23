package slug

import (
	"regexp"
	"strings"
	"unicode"
)

type SlugGenerator struct {
	separator string
}

func NewSlugGenerator() *SlugGenerator {
	return &SlugGenerator{
		separator: "-",
	}
}

func (sg *SlugGenerator) Generate(text string) string {
	text = strings.ToLower(text)

	text = removeAccents(text)

	reg := regexp.MustCompile("[^a-z0-9]+")
	text = reg.ReplaceAllString(text, sg.separator)

	text = strings.Trim(text, sg.separator)

	return text
}

func (sg *SlugGenerator) GenerateUnique(text string, suffix int) string {
	slug := sg.Generate(text)

	if suffix > 0 {
		slug = slug + sg.separator + string(rune(suffix))
	}

	return slug
}

func removeAccents(s string) string {
	t := make([]rune, 0, len(s))

	for _, r := range s {
		if r < unicode.MaxASCII {
			t = append(t, r)
		}
	}

	return string(t)
}
