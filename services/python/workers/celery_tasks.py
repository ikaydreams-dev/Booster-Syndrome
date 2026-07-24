from celery import Celery
import time

app = Celery('booster', broker='redis://localhost:6379/0')

@app.task
def send_email(to: str, subject: str, body: str):
    """Send email task"""
    print(f"Sending email to {to}: {subject}")
    time.sleep(1)  # Simulate email sending
    return {'status': 'sent', 'to': to}

@app.task
def process_image(image_path: str, operations: list):
    """Process image task"""
    print(f"Processing image: {image_path}")
    for op in operations:
        print(f"  - Applying {op}")
    time.sleep(2)
    return {'status': 'processed', 'path': image_path}

@app.task
def generate_report(user_id: int, report_type: str):
    """Generate report task"""
    print(f"Generating {report_type} report for user {user_id}")
    time.sleep(3)
    return {'status': 'completed', 'user_id': user_id, 'type': report_type}

@app.task
def cleanup_old_data(days: int = 30):
    """Cleanup old data task"""
    print(f"Cleaning up data older than {days} days")
    time.sleep(1)
    return {'status': 'cleaned', 'days': days}

@app.task
def sync_external_api(service: str):
    """Sync with external API task"""
    print(f"Syncing with {service}")
    time.sleep(2)
    return {'status': 'synced', 'service': service}
