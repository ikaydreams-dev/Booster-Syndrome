from sendgrid import SendGridAPIClient
from sendgrid.helpers.mail import Mail, Email, To, Content
import os

class EmailClient:
    def __init__(self):
        self.sg = SendGridAPIClient(api_key=os.environ.get('SENDGRID_API_KEY'))

    def send_email(self, to_email, subject, html_content):
        message = Mail(
            from_email=Email('noreply@boostersyndrome.com'),
            to_emails=To(to_email),
            subject=subject,
            html_content=Content('text/html', html_content)
        )

        try:
            response = self.sg.send(message)
            return {
                'status_code': response.status_code,
                'success': True
            }
        except Exception as e:
            return {
                'success': False,
                'error': str(e)
            }

    def send_bulk_email(self, recipients, subject, html_content):
        results = []
        for recipient in recipients:
            result = self.send_email(recipient, subject, html_content)
            results.append(result)
        return results
