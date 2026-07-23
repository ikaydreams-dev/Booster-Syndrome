package serialization

import (
	"encoding/json"
	"io"
	"os"
)

type JSONHandler struct{}

func NewJSONHandler() *JSONHandler {
	return &JSONHandler{}
}

func (jh *JSONHandler) Marshal(v interface{}) ([]byte, error) {
	return json.Marshal(v)
}

func (jh *JSONHandler) MarshalIndent(v interface{}) ([]byte, error) {
	return json.MarshalIndent(v, "", "  ")
}

func (jh *JSONHandler) Unmarshal(data []byte, v interface{}) error {
	return json.Unmarshal(data, v)
}

func (jh *JSONHandler) WriteToFile(filename string, v interface{}) error {
	file, err := os.Create(filename)
	if err != nil {
		return err
	}
	defer file.Close()

	encoder := json.NewEncoder(file)
	encoder.SetIndent("", "  ")
	return encoder.Encode(v)
}

func (jh *JSONHandler) ReadFromFile(filename string, v interface{}) error {
	file, err := os.Open(filename)
	if err != nil {
		return err
	}
	defer file.Close()

	decoder := json.NewDecoder(file)
	return decoder.Decode(v)
}

func (jh *JSONHandler) EncodeStream(w io.Writer, v interface{}) error {
	encoder := json.NewEncoder(w)
	return encoder.Encode(v)
}

func (jh *JSONHandler) DecodeStream(r io.Reader, v interface{}) error {
	decoder := json.NewDecoder(r)
	return decoder.Decode(v)
}
