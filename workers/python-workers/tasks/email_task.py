from celery import Celery
import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart

app = Celery('email_tasks', broker='redis://localhost:6379/0')

@app.task
def send_email_task(to_email, subject, body):
    """Send email asynchronously"""
    try:
        msg = MIMEMultipart()
        msg['From'] = 'noreply@example.com'
        msg['To'] = to_email
        msg['Subject'] = subject
        msg.attach(MIMEText(body, 'plain'))

        # TODO: Configure SMTP
        print(f"Email sent to {to_email}: {subject}")
        return {'status': 'sent', 'to': to_email}
    except Exception as e:
        return {'status': 'failed', 'error': str(e)}

@app.task
def send_bulk_emails(recipients, subject, body):
    """Send bulk emails"""
    results = []
    for recipient in recipients:
        result = send_email_task.delay(recipient, subject, body)
        results.append(result.id)
    return results
