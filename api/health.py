# Health check endpoint for Python services
import time
import psutil
from datetime import datetime

class HealthCheck:
    start_time = time.time()
    
    @classmethod
    def check(cls):
        return {
            'status': 'healthy',
            'timestamp': datetime.now().isoformat(),
            'service': 'python',
            'version': '1.0.0',
            'uptime': int(time.time() - cls.start_time),
            'dependencies': cls.check_dependencies()
        }
    
    @classmethod
    def check_dependencies(cls):
        return {
            'database': cls.check_database(),
            'redis': cls.check_redis(),
            'memory': cls.check_memory()
        }
    
    @staticmethod
    def check_database():
        # Simulated database check
        return {'status': 'connected', 'latency_ms': 5}
    
    @staticmethod
    def check_redis():
        # Simulated Redis check
        return {'status': 'connected', 'latency_ms': 2}
    
    @staticmethod
    def check_memory():
        process = psutil.Process()
        memory_mb = process.memory_info().rss / 1024 / 1024
        return {'used_mb': int(memory_mb), 'limit_mb': 512}

# Flask endpoint
def health_endpoint():
    from flask import jsonify
    return jsonify(HealthCheck.check()), 200
