import redis
import json
from datetime import timedelta

class RedisSessionManager:
    def __init__(self, host='localhost', port=6379, db=0):
        self.redis_client = redis.Redis(
            host=host,
            port=port,
            db=db,
            decode_responses=True
        )

    def create_session(self, session_id, user_data, ttl=3600):
        """Create new session"""
        key = f"session:{session_id}"
        self.redis_client.setex(
            key,
            timedelta(seconds=ttl),
            json.dumps(user_data)
        )
        return session_id

    def get_session(self, session_id):
        """Get session data"""
        key = f"session:{session_id}"
        data = self.redis_client.get(key)

        if data:
            return json.loads(data)
        return None

    def update_session(self, session_id, user_data):
        """Update session data"""
        key = f"session:{session_id}"
        ttl = self.redis_client.ttl(key)

        if ttl > 0:
            self.redis_client.setex(
                key,
                timedelta(seconds=ttl),
                json.dumps(user_data)
            )
            return True
        return False

    def delete_session(self, session_id):
        """Delete session"""
        key = f"session:{session_id}"
        return self.redis_client.delete(key) > 0

    def extend_session(self, session_id, ttl=3600):
        """Extend session TTL"""
        key = f"session:{session_id}"
        return self.redis_client.expire(key, ttl)

    def get_all_sessions(self, user_id):
        """Get all sessions for user"""
        pattern = f"session:*"
        sessions = []

        for key in self.redis_client.scan_iter(match=pattern):
            data = self.redis_client.get(key)
            if data:
                session_data = json.loads(data)
                if session_data.get('user_id') == user_id:
                    sessions.append({
                        'session_id': key.split(':')[1],
                        'data': session_data
                    })

        return sessions

    def revoke_all_sessions(self, user_id):
        """Revoke all sessions for user"""
        sessions = self.get_all_sessions(user_id)
        count = 0

        for session in sessions:
            if self.delete_session(session['session_id']):
                count += 1

        return count
