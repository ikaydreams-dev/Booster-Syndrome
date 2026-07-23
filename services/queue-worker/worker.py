import asyncio
import aio_pika
import json
import logging
from typing import Dict, Any
from datetime import datetime

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class QueueWorker:
    def __init__(self, rabbitmq_url: str):
        self.rabbitmq_url = rabbitmq_url
        self.connection = None
        self.channel = None
        self.handlers = {}

    async def connect(self):
        """Connect to RabbitMQ"""
        self.connection = await aio_pika.connect_robust(self.rabbitmq_url)
        self.channel = await self.connection.channel()
        await self.channel.set_qos(prefetch_count=10)
        logger.info("Connected to RabbitMQ")

    async def close(self):
        """Close connection"""
        if self.connection:
            await self.connection.close()
            logger.info("Connection closed")

    def register_handler(self, queue_name: str, handler):
        """Register message handler"""
        self.handlers[queue_name] = handler
        logger.info(f"Handler registered for queue: {queue_name}")

    async def consume(self, queue_name: str):
        """Consume messages from queue"""
        queue = await self.channel.declare_queue(queue_name, durable=True)

        async with queue.iterator() as queue_iter:
            async for message in queue_iter:
                async with message.process():
                    try:
                        data = json.loads(message.body.decode())
                        logger.info(f"Processing message from {queue_name}: {data}")

                        if queue_name in self.handlers:
                            await self.handlers[queue_name](data)
                        else:
                            logger.warning(f"No handler for queue: {queue_name}")

                    except Exception as e:
                        logger.error(f"Error processing message: {e}")

    async def publish(self, queue_name: str, message: Dict[str, Any]):
        """Publish message to queue"""
        queue = await self.channel.declare_queue(queue_name, durable=True)

        await self.channel.default_exchange.publish(
            aio_pika.Message(
                body=json.dumps(message).encode(),
                delivery_mode=aio_pika.DeliveryMode.PERSISTENT
            ),
            routing_key=queue_name
        )

        logger.info(f"Published message to {queue_name}")

    async def start_workers(self, queues: list):
        """Start consuming from multiple queues"""
        tasks = [self.consume(queue) for queue in queues]
        await asyncio.gather(*tasks)

# Message handlers
async def handle_email_queue(data: Dict[str, Any]):
    """Handle email sending"""
    logger.info(f"Sending email to {data.get('to')}")
    # Email sending logic
    await asyncio.sleep(1)  # Simulate work
    logger.info("Email sent successfully")

async def handle_notification_queue(data: Dict[str, Any]):
    """Handle push notifications"""
    logger.info(f"Sending notification to user {data.get('user_id')}")
    # Notification logic
    await asyncio.sleep(0.5)
    logger.info("Notification sent successfully")

async def handle_analytics_queue(data: Dict[str, Any]):
    """Handle analytics events"""
    logger.info(f"Processing analytics event: {data.get('event_type')}")
    # Analytics processing
    await asyncio.sleep(0.2)
    logger.info("Analytics event processed")

async def handle_webhook_queue(data: Dict[str, Any]):
    """Handle webhook deliveries"""
    logger.info(f"Delivering webhook to {data.get('url')}")
    # Webhook delivery
    await asyncio.sleep(1)
    logger.info("Webhook delivered")

async def main():
    rabbitmq_url = "amqp://guest:guest@localhost/"
    worker = QueueWorker(rabbitmq_url)

    await worker.connect()

    # Register handlers
    worker.register_handler("emails", handle_email_queue)
    worker.register_handler("notifications", handle_notification_queue)
    worker.register_handler("analytics", handle_analytics_queue)
    worker.register_handler("webhooks", handle_webhook_queue)

    # Start consuming
    queues = ["emails", "notifications", "analytics", "webhooks"]

    try:
        await worker.start_workers(queues)
    except KeyboardInterrupt:
        logger.info("Shutting down...")
    finally:
        await worker.close()

if __name__ == "__main__":
    asyncio.run(main())
