import redis
import json
import threading
from typing import Callable, Dict, Any

class RedisConsumer:
    """Redis Pub/Sub consumer"""
    
    def __init__(self, host: str = 'localhost', port: int = 6379, db: int = 0):
        self.redis_client = redis.Redis(host=host, port=port, db=db)
        self.pubsub = self.redis_client.pubsub()
        self.handlers: Dict[str, Callable] = {}
        self.running = False
        
    def subscribe(self, channel: str, handler: Callable[[Dict[str, Any]], None]):
        """Subscribe to a channel with a handler function"""
        self.handlers[channel] = handler
        self.pubsub.subscribe(channel)
        
    def unsubscribe(self, channel: str):
        """Unsubscribe from a channel"""
        self.pubsub.unsubscribe(channel)
        if channel in self.handlers:
            del self.handlers[channel]
    
    def start(self):
        """Start consuming messages"""
        self.running = True
        
        for message in self.pubsub.listen():
            if not self.running:
                break
                
            if message['type'] == 'message':
                channel = message['channel'].decode('utf-8')
                data = message['data'].decode('utf-8')
                
                try:
                    payload = json.loads(data)
                    
                    if channel in self.handlers:
                        self.handlers[channel](payload)
                except json.JSONDecodeError:
                    print(f"Invalid JSON from channel {channel}: {data}")
                except Exception as e:
                    print(f"Error processing message from {channel}: {e}")
    
    def start_async(self):
        """Start consuming messages in a background thread"""
        thread = threading.Thread(target=self.start, daemon=True)
        thread.start()
        return thread
    
    def stop(self):
        """Stop consuming messages"""
        self.running = False
        self.pubsub.close()
        
    def publish(self, channel: str, message: Dict[str, Any]):
        """Publish a message to a channel"""
        payload = json.dumps(message)
        self.redis_client.publish(channel, payload)

# Example usage
if __name__ == '__main__':
    consumer = RedisConsumer()
    
    def handle_user_events(message):
        print(f"User event: {message}")
    
    def handle_post_events(message):
        print(f"Post event: {message}")
    
    consumer.subscribe('user:events', handle_user_events)
    consumer.subscribe('post:events', handle_post_events)
    
    consumer.start()
