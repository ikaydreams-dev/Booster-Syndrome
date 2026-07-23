import requests
import os

class RecaptchaService:
    def __init__(self):
        self.secret_key = os.environ.get('RECAPTCHA_SECRET_KEY')
        self.verify_url = 'https://www.google.com/recaptcha/api/siteverify'

    def verify_token(self, token, remote_ip=None):
        """Verify reCAPTCHA token"""
        data = {
            'secret': self.secret_key,
            'response': token
        }

        if remote_ip:
            data['remoteip'] = remote_ip

        response = requests.post(self.verify_url, data=data)
        result = response.json()

        return {
            'success': result.get('success', False),
            'score': result.get('score', 0),
            'action': result.get('action'),
            'challenge_ts': result.get('challenge_ts')
        }

    def is_human(self, token, threshold=0.5):
        """Check if interaction is from human"""
        result = self.verify_token(token)
        return result['success'] and result.get('score', 0) >= threshold
