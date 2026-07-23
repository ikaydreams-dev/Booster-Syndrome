package hashing

import (
	"crypto/md5"
	"crypto/sha1"
	"crypto/sha256"
	"crypto/sha512"
	"encoding/hex"
	"hash"

	"golang.org/x/crypto/bcrypt"
)

type HashService struct{}

func NewHashService() *HashService {
	return &HashService{}
}

func (hs *HashService) MD5(data string) string {
	hasher := md5.New()
	hasher.Write([]byte(data))
	return hex.EncodeToString(hasher.Sum(nil))
}

func (hs *HashService) SHA1(data string) string {
	hasher := sha1.New()
	hasher.Write([]byte(data))
	return hex.EncodeToString(hasher.Sum(nil))
}

func (hs *HashService) SHA256(data string) string {
	hasher := sha256.New()
	hasher.Write([]byte(data))
	return hex.EncodeToString(hasher.Sum(nil))
}

func (hs *HashService) SHA512(data string) string {
	hasher := sha512.New()
	hasher.Write([]byte(data))
	return hex.EncodeToString(hasher.Sum(nil))
}

func (hs *HashService) BcryptHash(password string, cost int) (string, error) {
	bytes, err := bcrypt.GenerateFromPassword([]byte(password), cost)
	return string(bytes), err
}

func (hs *HashService) BcryptVerify(password, hash string) bool {
	err := bcrypt.CompareHashAndPassword([]byte(hash), []byte(password))
	return err == nil
}

func (hs *HashService) Hash(data string, algorithm string) string {
	var hasher hash.Hash

	switch algorithm {
	case "md5":
		hasher = md5.New()
	case "sha1":
		hasher = sha1.New()
	case "sha256":
		hasher = sha256.New()
	case "sha512":
		hasher = sha512.New()
	default:
		hasher = sha256.New()
	}

	hasher.Write([]byte(data))
	return hex.EncodeToString(hasher.Sum(nil))
}
