from pymongo import MongoClient
from typing import List, Dict, Any, Optional

class MongoDBConnector:
    def __init__(self, uri: str, database: str):
        self.client = MongoClient(uri)
        self.db = self.client[database]

    def insert_one(self, collection: str, document: Dict[str, Any]) -> str:
        """Insert single document"""
        result = self.db[collection].insert_one(document)
        return str(result.inserted_id)

    def insert_many(self, collection: str, documents: List[Dict[str, Any]]) -> List[str]:
        """Insert multiple documents"""
        result = self.db[collection].insert_many(documents)
        return [str(id) for id in result.inserted_ids]

    def find_one(self, collection: str, query: Dict[str, Any]) -> Optional[Dict[str, Any]]:
        """Find single document"""
        return self.db[collection].find_one(query)

    def find_many(self, collection: str, query: Dict[str, Any], limit: int = 100) -> List[Dict[str, Any]]:
        """Find multiple documents"""
        return list(self.db[collection].find(query).limit(limit))

    def update_one(self, collection: str, query: Dict[str, Any], update: Dict[str, Any]) -> int:
        """Update single document"""
        result = self.db[collection].update_one(query, {'$set': update})
        return result.modified_count

    def update_many(self, collection: str, query: Dict[str, Any], update: Dict[str, Any]) -> int:
        """Update multiple documents"""
        result = self.db[collection].update_many(query, {'$set': update})
        return result.modified_count

    def delete_one(self, collection: str, query: Dict[str, Any]) -> int:
        """Delete single document"""
        result = self.db[collection].delete_one(query)
        return result.deleted_count

    def delete_many(self, collection: str, query: Dict[str, Any]) -> int:
        """Delete multiple documents"""
        result = self.db[collection].delete_many(query)
        return result.deleted_count

    def aggregate(self, collection: str, pipeline: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
        """Execute aggregation pipeline"""
        return list(self.db[collection].aggregate(pipeline))

    def count(self, collection: str, query: Dict[str, Any] = {}) -> int:
        """Count documents"""
        return self.db[collection].count_documents(query)

    def close(self):
        """Close connection"""
        self.client.close()
