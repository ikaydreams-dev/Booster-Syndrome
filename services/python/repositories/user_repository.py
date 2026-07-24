from typing import Optional
from .base_repository import BaseRepository
from ..models.user import User

class UserRepository(BaseRepository[User]):
    """User repository"""
    
    def _get_model_class(self):
        return User

    def _get_table_name(self):
        return 'users'

    def _build_model(self, row: dict) -> User:
        return User(
            id=row['id'],
            email=row['email'],
            password_hash=row['password_hash'],
            created_at=row['created_at'],
            updated_at=row['updated_at']
        )

    def find_by_email(self, email: str) -> Optional[User]:
        """Find user by email"""
        query = "SELECT * FROM users WHERE email = %s"
        cursor = self.db.cursor()
        cursor.execute(query, (email,))
        row = cursor.fetchone()
        cursor.close()
        
        if not row:
            return None
        
        return self._build_model(row)

    def create(self, user: User) -> User:
        """Create a new user"""
        query = """
            INSERT INTO users (email, password_hash, created_at, updated_at)
            VALUES (%s, %s, %s, %s)
            RETURNING id
        """
        cursor = self.db.cursor()
        cursor.execute(
            query,
            (user.email, user.password_hash, user.created_at, user.updated_at)
        )
        user.id = cursor.fetchone()[0]
        self.db.commit()
        cursor.close()
        
        return user

    def update(self, user: User) -> User:
        """Update user"""
        query = """
            UPDATE users
            SET email = %s, password_hash = %s, updated_at = NOW()
            WHERE id = %s
        """
        cursor = self.db.cursor()
        cursor.execute(query, (user.email, user.password_hash, user.id))
        self.db.commit()
        cursor.close()
        
        return user
