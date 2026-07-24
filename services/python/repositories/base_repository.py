from typing import List, Optional, Type, TypeVar, Generic
from abc import ABC, abstractmethod

T = TypeVar('T')

class BaseRepository(ABC, Generic[T]):
    """Base repository with common CRUD operations"""
    
    def __init__(self, db_connection):
        self.db = db_connection
        self.model_class = self._get_model_class()
        self.table_name = self._get_table_name()

    @abstractmethod
    def _get_model_class(self) -> Type[T]:
        """Return the model class this repository manages"""
        pass

    @abstractmethod
    def _get_table_name(self) -> str:
        """Return the table name"""
        pass

    @abstractmethod
    def _build_model(self, row: dict) -> T:
        """Build a model instance from a database row"""
        pass

    def find(self, id: int) -> Optional[T]:
        """Find a record by ID"""
        query = f"SELECT * FROM {self.table_name} WHERE id = %s"
        cursor = self.db.cursor()
        cursor.execute(query, (id,))
        row = cursor.fetchone()
        cursor.close()
        
        if not row:
            return None
        
        return self._build_model(row)

    def all(self, limit: int = 100, offset: int = 0) -> List[T]:
        """Get all records with pagination"""
        query = f"SELECT * FROM {self.table_name} ORDER BY created_at DESC LIMIT %s OFFSET %s"
        cursor = self.db.cursor()
        cursor.execute(query, (limit, offset))
        rows = cursor.fetchall()
        cursor.close()
        
        return [self._build_model(row) for row in rows]

    def count(self) -> int:
        """Count total records"""
        query = f"SELECT COUNT(*) FROM {self.table_name}"
        cursor = self.db.cursor()
        cursor.execute(query)
        result = cursor.fetchone()
        cursor.close()
        
        return result[0] if result else 0

    def delete(self, id: int) -> bool:
        """Delete a record by ID"""
        query = f"DELETE FROM {self.table_name} WHERE id = %s"
        cursor = self.db.cursor()
        cursor.execute(query, (id,))
        affected = cursor.rowcount
        self.db.commit()
        cursor.close()
        
        return affected > 0
