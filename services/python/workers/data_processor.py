import asyncio
from typing import List, Dict, Any

class DataProcessor:
    """Async data processor for batch operations"""
    
    def __init__(self, batch_size: int = 100):
        self.batch_size = batch_size

    async def process_batch(self, items: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
        """Process a batch of items"""
        results = []
        
        for i in range(0, len(items), self.batch_size):
            batch = items[i:i + self.batch_size]
            batch_results = await asyncio.gather(
                *[self.process_item(item) for item in batch]
            )
            results.extend(batch_results)
        
        return results

    async def process_item(self, item: Dict[str, Any]) -> Dict[str, Any]:
        """Process a single item"""
        await asyncio.sleep(0.1)  # Simulate processing
        
        return {
            'id': item.get('id'),
            'status': 'processed',
            'result': item.get('data', {})
        }

    async def transform_data(self, data: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
        """Transform data asynchronously"""
        transformed = []
        
        for item in data:
            await asyncio.sleep(0.05)
            transformed.append({
                'original': item,
                'transformed': self._transform(item)
            })
        
        return transformed

    def _transform(self, item: Dict[str, Any]) -> Dict[str, Any]:
        """Transform a single item"""
        return {
            k.upper(): v
            for k, v in item.items()
        }
