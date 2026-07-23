import requests
from typing import Optional, Dict, Any

class GeoLocation:
    def __init__(self, ip: str, country: str, city: str, lat: float, lon: float):
        self.ip = ip
        self.country = country
        self.city = city
        self.latitude = lat
        self.longitude = lon

class GeoService:
    def __init__(self, api_key: Optional[str] = None):
        self.api_key = api_key
        self.cache: Dict[str, GeoLocation] = {}

    def get_location_by_ip(self, ip_address: str) -> Optional[GeoLocation]:
        """Get geolocation data from IP address"""
        if ip_address in self.cache:
            return self.cache[ip_address]

        try:
            url = f"http://ip-api.com/json/{ip_address}"
            response = requests.get(url, timeout=5)
            data = response.json()

            if data.get('status') == 'success':
                location = GeoLocation(
                    ip=ip_address,
                    country=data.get('country', ''),
                    city=data.get('city', ''),
                    lat=data.get('lat', 0.0),
                    lon=data.get('lon', 0.0)
                )

                self.cache[ip_address] = location
                return location

        except Exception as e:
            print(f"Geolocation lookup failed: {e}")

        return None

    def calculate_distance(self, lat1: float, lon1: float, lat2: float, lon2: float) -> float:
        """Calculate distance between two coordinates in kilometers"""
        from math import radians, sin, cos, sqrt, atan2

        R = 6371

        lat1_rad = radians(lat1)
        lat2_rad = radians(lat2)
        delta_lat = radians(lat2 - lat1)
        delta_lon = radians(lon2 - lon1)

        a = sin(delta_lat / 2) ** 2 + cos(lat1_rad) * cos(lat2_rad) * sin(delta_lon / 2) ** 2
        c = 2 * atan2(sqrt(a), sqrt(1 - a))

        distance = R * c

        return distance

    def is_within_radius(self, lat1: float, lon1: float, lat2: float, lon2: float, radius_km: float) -> bool:
        """Check if two coordinates are within specified radius"""
        distance = self.calculate_distance(lat1, lon1, lat2, lon2)
        return distance <= radius_km

    def get_country_by_ip(self, ip_address: str) -> Optional[str]:
        """Get country code from IP address"""
        location = self.get_location_by_ip(ip_address)
        return location.country if location else None

    def get_city_by_ip(self, ip_address: str) -> Optional[str]:
        """Get city from IP address"""
        location = self.get_location_by_ip(ip_address)
        return location.city if location else None

geo_service = GeoService()
