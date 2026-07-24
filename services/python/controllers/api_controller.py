from flask import jsonify, request
from functools import wraps

class APIController:
    def __init__(self, service):
        self.service = service

    def list(self):
        """List all resources"""
        page = request.args.get('page', 1, type=int)
        per_page = request.args.get('per_page', 20, type=int)
        
        items = self.service.paginate(page=page, per_page=per_page)
        total = self.service.count()
        
        return jsonify({
            'data': [item.to_dict() for item in items],
            'pagination': {
                'page': page,
                'per_page': per_page,
                'total': total,
                'total_pages': (total + per_page - 1) // per_page
            }
        }), 200

    def get(self, id):
        """Get a single resource"""
        item = self.service.find(id)
        if not item:
            return jsonify({'error': 'Not found'}), 404
        
        return jsonify(item.to_dict()), 200

    def create(self):
        """Create a new resource"""
        data = request.get_json()
        result = self.service.create(data)
        
        if result.success:
            return jsonify(result.value.to_dict()), 201
        else:
            return jsonify({'errors': result.errors}), 422

    def update(self, id):
        """Update a resource"""
        data = request.get_json()
        result = self.service.update(id, data)
        
        if result.success:
            return jsonify(result.value.to_dict()), 200
        else:
            return jsonify({'errors': result.errors}), 422

    def delete(self, id):
        """Delete a resource"""
        result = self.service.delete(id)
        
        if result.success:
            return '', 204
        else:
            return jsonify({'error': 'Not found'}), 404


def require_auth(f):
    """Decorator to require authentication"""
    @wraps(f)
    def decorated_function(*args, **kwargs):
        token = request.headers.get('Authorization', '').replace('Bearer ', '')
        if not token:
            return jsonify({'error': 'No token provided'}), 401
        
        # Verify token here
        return f(*args, **kwargs)
    
    return decorated_function
