import os
import time
import redis
import json
from datetime import datetime

redis_client = redis.from_url(os.getenv('REDIS_URL', 'redis://localhost:6379'))

def process_job(job_data):
    """Process a background job"""
    print(f"Processing job: {job_data}")
    time.sleep(2)
    print(f"Job completed: {job_data}")

def main():
    print("Python worker started...")

    while True:
        try:
            _, job = redis_client.blpop(['jobs'], timeout=5)

            if job:
                job_data = json.loads(job)
                process_job(job_data)

        except KeyboardInterrupt:
            print("Worker shutting down...")
            break
        except Exception as e:
            print(f"Error: {e}")
            time.sleep(1)

if __name__ == "__main__":
    main()
