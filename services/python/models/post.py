from datetime import datetime
from typing import Optional

class Post:
    def __init__(
        self,
        title: str,
        content: str,
        user_id: int,
        id: Optional[int] = None,
        published: bool = False,
        created_at: Optional[datetime] = None,
        updated_at: Optional[datetime] = None
    ):
        self.id = id
        self.user_id = user_id
        self.title = title
        self.content = content
        self.published = published
        self.created_at = created_at or datetime.now()
        self.updated_at = updated_at or datetime.now()

    def publish(self):
        """Mark the post as published"""
        self.published = True
        self.updated_at = datetime.now()

    def unpublish(self):
        """Mark the post as unpublished"""
        self.published = False
        self.updated_at = datetime.now()

    def to_dict(self) -> dict:
        """Convert to dictionary"""
        return {
            'id': self.id,
            'user_id': self.user_id,
            'title': self.title,
            'content': self.content,
            'published': self.published,
            'created_at': self.created_at.isoformat() if self.created_at else None,
            'updated_at': self.updated_at.isoformat() if self.updated_at else None
        }

    def __repr__(self):
        return f"<Post(id={self.id}, title={self.title}, published={self.published})>"
