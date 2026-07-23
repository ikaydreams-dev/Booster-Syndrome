import requests

class LocationService:
    def __init__(self, api_key=None):
        self.api_key = api_key
        self.geocode_url = "https://maps.googleapis.com/maps/api/geocode/json"

    def geocode_address(self, address):
        """Convert address to coordinates"""
        params = {
            'address': address,
            'key': self.api_key
        }

        response = requests.get(self.geocode_url, params=params)
        data = response.json()

        if data['status'] == 'OK':
            location = data['results'][0]['geometry']['location']
            return {
                'latitude': location['lat'],
                'longitude': location['lng'],
                'formatted_address': data['results'][0]['formatted_address']
            }

        return None

    def reverse_geocode(self, latitude, longitude):
        """Convert coordinates to address"""
        params = {
            'latlng': f"{latitude},{longitude}",
            'key': self.api_key
        }

        response = requests.get(self.geocode_url, params=params)
        data = response.json()

        if data['status'] == 'OK':
            return {
                'formatted_address': data['results'][0]['formatted_address'],
                'components': data['results'][0]['address_components']
            }

        return None

    def calculate_distance(self, lat1, lon1, lat2, lon2):
        """Calculate distance between two points"""
        from math import radians, sin, cos, sqrt, atan2

        R = 6371  # Earth radius in km

        lat1, lon1, lat2, lon2 = map(radians, [lat1, lon1, lat2, lon2])

        dlat = lat2 - lat1
        dlon = lon2 - lon1

        a = sin(dlat/2)**2 + cos(lat1) * cos(lat2) * sin(dlon/2)**2
        c = 2 * atan2(sqrt(a), sqrt(1-a))

        distance = R * c
        return distance
