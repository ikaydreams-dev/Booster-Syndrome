package xml

import (
	"encoding/xml"
	"io"
	"os"
)

type XMLParser struct{}

func NewXMLParser() *XMLParser {
	return &XMLParser{}
}

func (xp *XMLParser) ParseFile(filename string, v interface{}) error {
	file, err := os.Open(filename)
	if err != nil {
		return err
	}
	defer file.Close()

	decoder := xml.NewDecoder(file)
	return decoder.Decode(v)
}

func (xp *XMLParser) ParseString(data string, v interface{}) error {
	return xml.Unmarshal([]byte(data), v)
}

func (xp *XMLParser) ParseReader(reader io.Reader, v interface{}) error {
	decoder := xml.NewDecoder(reader)
	return decoder.Decode(v)
}

func (xp *XMLParser) Marshal(v interface{}) ([]byte, error) {
	return xml.MarshalIndent(v, "", "  ")
}

func (xp *XMLParser) WriteToFile(filename string, v interface{}) error {
	data, err := xp.Marshal(v)
	if err != nil {
		return err
	}

	return os.WriteFile(filename, data, 0644)
}

type RSS struct {
	XMLName xml.Name `xml:"rss"`
	Version string   `xml:"version,attr"`
	Channel Channel  `xml:"channel"`
}

type Channel struct {
	Title       string `xml:"title"`
	Link        string `xml:"link"`
	Description string `xml:"description"`
	Items       []Item `xml:"item"`
}

type Item struct {
	Title       string `xml:"title"`
	Link        string `xml:"link"`
	Description string `xml:"description"`
	PubDate     string `xml:"pubDate"`
}

func (xp *XMLParser) GenerateRSS(title, link, description string, items []Item) ([]byte, error) {
	rss := RSS{
		Version: "2.0",
		Channel: Channel{
			Title:       title,
			Link:        link,
			Description: description,
			Items:       items,
		},
	}

	return xp.Marshal(rss)
}
