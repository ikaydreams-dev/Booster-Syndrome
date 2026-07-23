import asyncio
from datetime import datetime
from typing import Dict, Any
import json
import logging

logger = logging.getLogger(__name__)

class EventProcessor:
    """Background worker for processing analytics events"""

    def __init__(self, redis_client, db_pool):
        self.redis = redis_client
        self.db = db_pool
        self.running = False

    async def start(self):
        """Start the event processor worker"""
        self.running = True
        logger.info("Event processor started")

        while self.running:
            try:
                # Pop event from queue
                event_data = await self.redis.blpop('events:queue', timeout=5)

                if event_data:
                    _, event_json = event_data
                    event = json.loads(event_json)
                    await self.process_event(event)

            except Exception as e:
                logger.error(f"Error processing event: {e}")
                await asyncio.sleep(1)

    async def process_event(self, event: Dict[str, Any]):
        """Process a single analytics event"""
        try:
            # Enrich event with metadata
            enriched_event = await self.enrich_event(event)

            # Store in database
            await self.store_event(enriched_event)

            # Update real-time metrics
            await self.update_metrics(enriched_event)

            # Trigger webhooks if needed
            await self.trigger_webhooks(enriched_event)

            logger.info(f"Processed event: {enriched_event['event_type']}")

        except Exception as e:
            logger.error(f"Failed to process event: {e}")
            # Re-queue failed event
            await self.redis.rpush('events:failed', json.dumps(event))

    async def enrich_event(self, event: Dict[str, Any]) -> Dict[str, Any]:
        """Add additional metadata to event"""
        event['processed_at'] = datetime.utcnow().isoformat()

        # Parse user agent if available
        if 'user_agent' in event:
            # Add browser, OS, device detection
            pass

        # GeoIP lookup
        if 'ip_address' in event:
            # Add country, city detection
            pass

        return event

    async def store_event(self, event: Dict[str, Any]):
        """Store event in database"""
        query = """
            INSERT INTO events (user_id, event_type, event_name, properties, timestamp)
            VALUES ($1, $2, $3, $4, $5)
        """
        await self.db.execute(
            query,
            event.get('user_id'),
            event['event_type'],
            event['event_name'],
            json.dumps(event.get('properties', {})),
            datetime.fromisoformat(event['processed_at'])
        )

    async def update_metrics(self, event: Dict[str, Any]):
        """Update real-time metrics in Redis"""
        # Increment counters
        await self.redis.hincrby('metrics:events', event['event_type'], 1)
        await self.redis.hincrby('metrics:daily', datetime.utcnow().strftime('%Y-%m-%d'), 1)

        # Track unique users
        if 'user_id' in event:
            await self.redis.sadd('metrics:active_users', event['user_id'])

    async def trigger_webhooks(self, event: Dict[str, Any]):
        """Trigger registered webhooks for this event type"""
        # Implementation for webhook triggering
        pass

    async def stop(self):
        """Stop the event processor"""
        self.running = False
        logger.info("Event processor stopped")
