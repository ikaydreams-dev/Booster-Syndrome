package iplocation

import (
	"encoding/json"
	"fmt"
	"net"
	"net/http"
	"time"
)

type GeoIPService struct {
	client *http.Client
}

type Location struct {
	IP        string  `json:"ip"`
	City      string  `json:"city"`
	Region    string  `json:"region"`
	Country   string  `json:"country"`
	Loc       string  `json:"loc"`
	Org       string  `json:"org"`
	Postal    string  `json:"postal"`
	Timezone  string  `json:"timezone"`
	Latitude  float64 `json:"latitude"`
	Longitude float64 `json:"longitude"`
}

func NewGeoIPService() *GeoIPService {
	return &GeoIPService{
		client: &http.Client{
			Timeout: 10 * time.Second,
		},
	}
}

func (g *GeoIPService) GetLocation(ip string) (*Location, error) {
	url := fmt.Sprintf("https://ipinfo.io/%s/json", ip)

	resp, err := g.client.Get(url)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	var location Location
	if err := json.NewDecoder(resp.Body).Decode(&location); err != nil {
		return nil, err
	}

	return &location, nil
}

func (g *GeoIPService) IsLocal(ip string) bool {
	parsedIP := net.ParseIP(ip)
	if parsedIP == nil {
		return false
	}

	return parsedIP.IsLoopback() || parsedIP.IsPrivate()
}

func (g *GeoIPService) ValidateIP(ip string) bool {
	return net.ParseIP(ip) != nil
}
