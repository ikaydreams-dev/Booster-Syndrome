from twilio.rest import Client
import os

class TwilioService:
    def __init__(self):
        self.account_sid = os.environ.get('TWILIO_ACCOUNT_SID')
        self.auth_token = os.environ.get('TWILIO_AUTH_TOKEN')
        self.phone_number = os.environ.get('TWILIO_PHONE_NUMBER')
        self.client = Client(self.account_sid, self.auth_token)

    def send_sms(self, to_number, message):
        try:
            message = self.client.messages.create(
                body=message,
                from_=self.phone_number,
                to=to_number
            )
            return {
                'success': True,
                'message_sid': message.sid
            }
        except Exception as e:
            return {
                'success': False,
                'error': str(e)
            }

    def send_verification_code(self, to_number, code):
        message = f"Your verification code is: {code}"
        return self.send_sms(to_number, message)
