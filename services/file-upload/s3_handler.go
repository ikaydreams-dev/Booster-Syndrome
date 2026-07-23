package fileupload

import (
	"context"
	"fmt"
	"io"
	"mime/multipart"
	"path/filepath"
	"time"

	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/service/s3"
	"github.com/google/uuid"
)

type S3Uploader struct {
	client *s3.Client
	bucket string
}

func NewS3Uploader(client *s3.Client, bucket string) *S3Uploader {
	return &S3Uploader{
		client: client,
		bucket: bucket,
	}
}

type UploadResult struct {
	Key      string `json:"key"`
	URL      string `json:"url"`
	Size     int64  `json:"size"`
	MimeType string `json:"mimeType"`
}

func (u *S3Uploader) UploadFile(ctx context.Context, file multipart.File, header *multipart.FileHeader, folder string) (*UploadResult, error) {
	defer file.Close()

	ext := filepath.Ext(header.Filename)
	filename := fmt.Sprintf("%s%s", uuid.New().String(), ext)
	key := filepath.Join(folder, filename)

	_, err := u.client.PutObject(ctx, &s3.PutObjectInput{
		Bucket:      aws.String(u.bucket),
		Key:         aws.String(key),
		Body:        file,
		ContentType: aws.String(header.Header.Get("Content-Type")),
	})

	if err != nil {
		return nil, err
	}

	url := fmt.Sprintf("https://%s.s3.amazonaws.com/%s", u.bucket, key)

	return &UploadResult{
		Key:      key,
		URL:      url,
		Size:     header.Size,
		MimeType: header.Header.Get("Content-Type"),
	}, nil
}

func (u *S3Uploader) UploadMultiple(ctx context.Context, files []*multipart.FileHeader, folder string) ([]*UploadResult, error) {
	results := make([]*UploadResult, 0, len(files))

	for _, fileHeader := range files {
		file, err := fileHeader.Open()
		if err != nil {
			return nil, err
		}

		result, err := u.UploadFile(ctx, file, fileHeader, folder)
		if err != nil {
			return nil, err
		}

		results = append(results, result)
	}

	return results, nil
}

func (u *S3Uploader) DeleteFile(ctx context.Context, key string) error {
	_, err := u.client.DeleteObject(ctx, &s3.DeleteObjectInput{
		Bucket: aws.String(u.bucket),
		Key:    aws.String(key),
	})

	return err
}

func (u *S3Uploader) GetPresignedURL(ctx context.Context, key string, expiration time.Duration) (string, error) {
	presignClient := s3.NewPresignClient(u.client)

	req, err := presignClient.PresignGetObject(ctx, &s3.GetObjectInput{
		Bucket: aws.String(u.bucket),
		Key:    aws.String(key),
	}, func(opts *s3.PresignOptions) {
		opts.Expires = expiration
	})

	if err != nil {
		return "", err
	}

	return req.URL, nil
}

func (u *S3Uploader) GetFile(ctx context.Context, key string) (io.ReadCloser, error) {
	result, err := u.client.GetObject(ctx, &s3.GetObjectInput{
		Bucket: aws.String(u.bucket),
		Key:    aws.String(key),
	})

	if err != nil {
		return nil, err
	}

	return result.Body, nil
}

func ValidateFileSize(size int64, maxSize int64) error {
	if size > maxSize {
		return fmt.Errorf("file size %d exceeds maximum allowed size %d", size, maxSize)
	}
	return nil
}

func ValidateFileType(mimeType string, allowedTypes []string) error {
	for _, allowed := range allowedTypes {
		if mimeType == allowed {
			return nil
		}
	}
	return fmt.Errorf("file type %s not allowed", mimeType)
}
