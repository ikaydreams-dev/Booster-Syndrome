package validators

import (
	"net/mail"
	"net/url"
	"regexp"
	"strings"
	"unicode"
)

type Validator struct{}

func NewValidator() *Validator {
	return &Validator{}
}

func (v *Validator) IsEmail(email string) bool {
	_, err := mail.ParseAddress(email)
	return err == nil
}

func (v *Validator) IsURL(rawURL string) bool {
	u, err := url.Parse(rawURL)
	return err == nil && u.Scheme != "" && u.Host != ""
}

func (v *Validator) IsAlpha(s string) bool {
	for _, r := range s {
		if !unicode.IsLetter(r) {
			return false
		}
	}
	return len(s) > 0
}

func (v *Validator) IsAlphanumeric(s string) bool {
	for _, r := range s {
		if !unicode.IsLetter(r) && !unicode.IsDigit(r) {
			return false
		}
	}
	return len(s) > 0
}

func (v *Validator) IsNumeric(s string) bool {
	for _, r := range s {
		if !unicode.IsDigit(r) {
			return false
		}
	}
	return len(s) > 0
}

func (v *Validator) MinLength(s string, min int) bool {
	return len(s) >= min
}

func (v *Validator) MaxLength(s string, max int) bool {
	return len(s) <= max
}

func (v *Validator) Between(s string, min, max int) bool {
	length := len(s)
	return length >= min && length <= max
}

func (v *Validator) IsIPv4(ip string) bool {
	pattern := `^((25[0-5]|(2[0-4]|1\d|[1-9]|)\d)\.?\b){4}$`
	matched, _ := regexp.MatchString(pattern, ip)
	return matched
}

func (v *Validator) IsIPv6(ip string) bool {
	pattern := `^(([0-9a-fA-F]{1,4}:){7}[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,7}:|([0-9a-fA-F]{1,4}:){1,6}:[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,5}(:[0-9a-fA-F]{1,4}){1,2}|([0-9a-fA-F]{1,4}:){1,4}(:[0-9a-fA-F]{1,4}){1,3}|([0-9a-fA-F]{1,4}:){1,3}(:[0-9a-fA-F]{1,4}){1,4}|([0-9a-fA-F]{1,4}:){1,2}(:[0-9a-fA-F]{1,4}){1,5}|[0-9a-fA-F]{1,4}:((:[0-9a-fA-F]{1,4}){1,6})|:((:[0-9a-fA-F]{1,4}){1,7}|:)|fe80:(:[0-9a-fA-F]{0,4}){0,4}%[0-9a-zA-Z]+|::(ffff(:0{1,4})?:)?((25[0-5]|(2[0-4]|1?[0-9])?[0-9])\.){3}(25[0-5]|(2[0-4]|1?[0-9])?[0-9])|([0-9a-fA-F]{1,4}:){1,4}:((25[0-5]|(2[0-4]|1?[0-9])?[0-9])\.){3}(25[0-5]|(2[0-4]|1?[0-9])?[0-9]))$`
	matched, _ := regexp.MatchString(pattern, ip)
	return matched
}

func (v *Validator) IsUUID(uuid string) bool {
	pattern := `^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$`
	matched, _ := regexp.MatchString(pattern, uuid)
	return matched
}

func (v *Validator) IsHexColor(color string) bool {
	pattern := `^#?([0-9a-fA-F]{3}|[0-9a-fA-F]{6})$`
	matched, _ := regexp.MatchString(pattern, color)
	return matched
}

func (v *Validator) IsCreditCard(card string) bool {
	card = strings.ReplaceAll(card, " ", "")
	card = strings.ReplaceAll(card, "-", "")

	if !v.IsNumeric(card) || len(card) < 13 || len(card) > 19 {
		return false
	}

	sum := 0
	double := false

	for i := len(card) - 1; i >= 0; i-- {
		digit := int(card[i] - '0')

		if double {
			digit *= 2
			if digit > 9 {
				digit -= 9
			}
		}

		sum += digit
		double = !double
	}

	return sum%10 == 0
}

func (v *Validator) IsStrongPassword(password string) bool {
	if len(password) < 8 {
		return false
	}

	hasUpper := false
	hasLower := false
	hasDigit := false
	hasSpecial := false

	for _, r := range password {
		switch {
		case unicode.IsUpper(r):
			hasUpper = true
		case unicode.IsLower(r):
			hasLower = true
		case unicode.IsDigit(r):
			hasDigit = true
		case unicode.IsPunct(r) || unicode.IsSymbol(r):
			hasSpecial = true
		}
	}

	return hasUpper && hasLower && hasDigit && hasSpecial
}
