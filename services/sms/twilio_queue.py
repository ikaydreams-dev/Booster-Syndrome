from twilio.rest import Client
from typing import Optional, List
import asyncio
from datetime import datetime

class SMSQueue:
    def __init__(self, account_sid: str, auth_token: str, from_number: str):
        self.client = Client(account_sid, auth_token)
        self.from_number = from_number
        self.queue: List[dict] = []

    def send_sms(self, to: str, body: str) -> Optional[str]:
        """Send SMS immediately"""
        try:
            message = self.client.messages.create(
                body=body,
                from_=self.from_number,
                to=to
            )
            return message.sid
        except Exception as e:
            print(f"SMS send failed: {e}")
            return None

    def queue_sms(self, to: str, body: str, scheduled_at: Optional[datetime] = None):
        """Queue SMS for later sending"""
        self.queue.append({
            'to': to,
            'body': body,
            'scheduled_at': scheduled_at or datetime.now(),
            'status': 'queued'
        })

    async def process_queue(self):
        """Process queued SMS messages"""
        while self.queue:
            message = self.queue[0]

            if datetime.now() >= message['scheduled_at']:
                result = self.send_sms(message['to'], message['body'])

                if result:
                    message['status'] = 'sent'
                    message['sid'] = result
                else:
                    message['status'] = 'failed'

                self.queue.pop(0)
            else:
                await asyncio.sleep(1)

    def send_bulk_sms(self, recipients: List[str], body: str) -> List[Optional[str]]:
        """Send SMS to multiple recipients"""
        results = []

        for recipient in recipients:
            result = self.send_sms(recipient, body)
            results.append(result)

        return results

    def get_message_status(self, message_sid: str) -> Optional[dict]:
        """Get status of sent message"""
        try:
            message = self.client.messages(message_sid).fetch()
            return {
                'sid': message.sid,
                'status': message.status,
                'to': message.to,
                'from': message.from_,
                'body': message.body,
                'date_sent': message.date_sent,
                'error_code': message.error_code,
                'error_message': message.error_message
            }
        except Exception as e:
            print(f"Failed to fetch message status: {e}")
            return None
