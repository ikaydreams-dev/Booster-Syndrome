from typing import List, Any, Callable

class ArrayOperations:
    @staticmethod
    def chunk(arr: List[Any], size: int) -> List[List[Any]]:
        """Split array into chunks"""
        return [arr[i:i + size] for i in range(0, len(arr), size)]

    @staticmethod
    def flatten(arr: List[Any]) -> List[Any]:
        """Flatten nested arrays"""
        result = []
        for item in arr:
            if isinstance(item, list):
                result.extend(ArrayOperations.flatten(item))
            else:
                result.append(item)
        return result

    @staticmethod
    def unique(arr: List[Any]) -> List[Any]:
        """Remove duplicates while preserving order"""
        seen = set()
        result = []
        for item in arr:
            if item not in seen:
                seen.add(item)
                result.append(item)
        return result

    @staticmethod
    def difference(arr1: List[Any], arr2: List[Any]) -> List[Any]:
        """Elements in arr1 not in arr2"""
        return [x for x in arr1 if x not in arr2]

    @staticmethod
    def intersection(arr1: List[Any], arr2: List[Any]) -> List[Any]:
        """Common elements"""
        return list(set(arr1) & set(arr2))

    @staticmethod
    def union(arr1: List[Any], arr2: List[Any]) -> List[Any]:
        """All unique elements"""
        return list(set(arr1) | set(arr2))

    @staticmethod
    def partition(arr: List[Any], predicate: Callable) -> tuple:
        """Split array based on predicate"""
        passed = [x for x in arr if predicate(x)]
        failed = [x for x in arr if not predicate(x)]
        return passed, failed

    @staticmethod
    def group_by(arr: List[Any], key_func: Callable) -> dict:
        """Group array elements by key function"""
        result = {}
        for item in arr:
            key = key_func(item)
            if key not in result:
                result[key] = []
            result[key].append(item)
        return result

    @staticmethod
    def sample(arr: List[Any], n: int) -> List[Any]:
        """Random sample of n elements"""
        import random
        return random.sample(arr, min(n, len(arr)))

    @staticmethod
    def shuffle(arr: List[Any]) -> List[Any]:
        """Randomly shuffle array"""
        import random
        result = arr.copy()
        random.shuffle(result)
        return result

    @staticmethod
    def rotate(arr: List[Any], k: int) -> List[Any]:
        """Rotate array k positions"""
        if not arr:
            return arr
        k = k % len(arr)
        return arr[k:] + arr[:k]

    @staticmethod
    def zip_arrays(*arrays) -> List[tuple]:
        """Zip multiple arrays together"""
        return list(zip(*arrays))

    @staticmethod
    def compact(arr: List[Any]) -> List[Any]:
        """Remove falsy values"""
        return [x for x in arr if x]

    @staticmethod
    def pluck(arr: List[dict], key: str) -> List[Any]:
        """Extract value at key from each dict"""
        return [item.get(key) for item in arr]

array_ops = ArrayOperations()
