from datetime import datetime
from typing import Optional

class Comment:
    def __init__(
        self,
        content: str,
        post_id: int,
        user_id: int,
        id: Optional[int] = None,
        created_at: Optional[datetime] = None,
        updated_at: Optional[datetime] = None
    ):
        self.id = id
        self.post_id = post_id
        self.user_id = user_id
        self.content = content
        self.created_at = created_at or datetime.now()
        self.updated_at = updated_at or datetime.now()

    def update_content(self, new_content: str):
        """Update the comment content"""
        self.content = new_content
        self.updated_at = datetime.now()

    def to_dict(self) -> dict:
        """Convert to dictionary"""
        return {
            'id': self.id,
            'post_id': self.post_id,
            'user_id': self.user_id,
            'content': self.content,
            'created_at': self.created_at.isoformat() if self.created_at else None,
            'updated_at': self.updated_at.isoformat() if self.updated_at else None
        }

    def __repr__(self):
        return f"<Comment(id={self.id}, post_id={self.post_id})>"
