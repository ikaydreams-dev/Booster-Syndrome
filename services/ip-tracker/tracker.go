package iptracker

import (
	"encoding/json"
	"fmt"
	"net/http"
)

type IPInfo struct {
	IP       string  `json:"ip"`
	City     string  `json:"city"`
	Region   string  `json:"region"`
	Country  string  `json:"country"`
	Lat      float64 `json:"latitude"`
	Lon      float64 `json:"longitude"`
	Timezone string  `json:"timezone"`
}

type IPTracker struct {
	apiKey string
}

func NewIPTracker(apiKey string) *IPTracker {
	return &IPTracker{
		apiKey: apiKey,
	}
}

func (it *IPTracker) Lookup(ip string) (*IPInfo, error) {
	url := fmt.Sprintf("https://ipapi.co/%s/json/", ip)

	resp, err := http.Get(url)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	var info IPInfo
	if err := json.NewDecoder(resp.Body).Decode(&info); err != nil {
		return nil, err
	}

	return &info, nil
}

func (it *IPTracker) IsVPN(ip string) bool {
	// VPN detection logic
	return false
}

func (it *IPTracker) IsProxy(ip string) bool {
	// Proxy detection logic
	return false
}
