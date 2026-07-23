import json
from datetime import datetime

class AuditLogger:
    def __init__(self, db_connection):
        self.db = db_connection

    def log_action(self, user_id, action, resource, details=None):
        """Log user action"""
        log_entry = {
            'user_id': user_id,
            'action': action,
            'resource': resource,
            'details': details or {},
            'timestamp': datetime.utcnow().isoformat(),
            'ip_address': None  # Set from request context
        }

        # Store in database
        self.db.audit_logs.insert_one(log_entry)

        return log_entry

    def log_login(self, user_id, ip_address, success=True):
        """Log login attempt"""
        return self.log_action(
            user_id,
            'login',
            'authentication',
            {'ip_address': ip_address, 'success': success}
        )

    def log_data_access(self, user_id, resource_type, resource_id):
        """Log data access"""
        return self.log_action(
            user_id,
            'read',
            resource_type,
            {'resource_id': resource_id}
        )

    def log_data_modification(self, user_id, resource_type, resource_id, changes):
        """Log data modification"""
        return self.log_action(
            user_id,
            'update',
            resource_type,
            {'resource_id': resource_id, 'changes': changes}
        )

    def get_user_audit_trail(self, user_id, limit=100):
        """Get audit trail for user"""
        return list(self.db.audit_logs.find(
            {'user_id': user_id}
        ).sort('timestamp', -1).limit(limit))
