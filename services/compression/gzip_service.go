package compression

import (
	"bytes"
	"compress/gzip"
	"io"
)

type CompressionService struct{}

func NewCompressionService() *CompressionService {
	return &CompressionService{}
}

func (cs *CompressionService) Compress(data []byte) ([]byte, error) {
	var buf bytes.Buffer
	writer := gzip.NewWriter(&buf)

	_, err := writer.Write(data)
	if err != nil {
		return nil, err
	}

	err = writer.Close()
	if err != nil {
		return nil, err
	}

	return buf.Bytes(), nil
}

func (cs *CompressionService) Decompress(data []byte) ([]byte, error) {
	reader, err := gzip.NewReader(bytes.NewReader(data))
	if err != nil {
		return nil, err
	}
	defer reader.Close()

	var buf bytes.Buffer
	_, err = io.Copy(&buf, reader)
	if err != nil {
		return nil, err
	}

	return buf.Bytes(), nil
}

func (cs *CompressionService) CompressString(str string) ([]byte, error) {
	return cs.Compress([]byte(str))
}

func (cs *CompressionService) DecompressToString(data []byte) (string, error) {
	decompressed, err := cs.Decompress(data)
	if err != nil {
		return "", err
	}

	return string(decompressed), nil
}
