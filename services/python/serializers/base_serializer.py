from typing import Any, Dict, List, Optional
from datetime import datetime

class BaseSerializer:
    """Base serializer for all models"""
    
    def __init__(self, instance, many: bool = False, context: Optional[Dict] = None):
        self.instance = instance
        self.many = many
        self.context = context or {}
    
    def serialize(self) -> Any:
        """Main serialization method"""
        if self.many:
            return [self.to_dict(item) for item in self.instance]
        return self.to_dict(self.instance)
    
    def to_dict(self, instance) -> Dict[str, Any]:
        """Override this method in subclasses"""
        raise NotImplementedError("Subclasses must implement to_dict method")
    
    def format_datetime(self, dt: Optional[datetime]) -> Optional[str]:
        """Format datetime to ISO 8601 string"""
        return dt.isoformat() if dt else None
    
    def get_related(self, obj, field: str, serializer_class):
        """Helper to serialize related objects"""
        related = getattr(obj, field, None)
        if related is None:
            return None
        
        if isinstance(related, list):
            return serializer_class(related, many=True, context=self.context).serialize()
        return serializer_class(related, context=self.context).serialize()
