from typing import Set, TypeVar, Generic, Iterator

T = TypeVar('T')

class CustomSet(Generic[T]):
    def __init__(self, elements=None):
        self._data: Set[T] = set(elements) if elements else set()

    def add(self, element: T) -> None:
        self._data.add(element)

    def remove(self, element: T) -> None:
        self._data.remove(element)

    def discard(self, element: T) -> None:
        self._data.discard(element)

    def pop(self) -> T:
        return self._data.pop()

    def clear(self) -> None:
        self._data.clear()

    def contains(self, element: T) -> bool:
        return element in self._data

    def size(self) -> int:
        return len(self._data)

    def is_empty(self) -> bool:
        return len(self._data) == 0

    def union(self, other: 'CustomSet[T]') -> 'CustomSet[T]':
        return CustomSet(self._data | other._data)

    def intersection(self, other: 'CustomSet[T]') -> 'CustomSet[T]':
        return CustomSet(self._data & other._data)

    def difference(self, other: 'CustomSet[T]') -> 'CustomSet[T]':
        return CustomSet(self._data - other._data)

    def symmetric_difference(self, other: 'CustomSet[T]') -> 'CustomSet[T]':
        return CustomSet(self._data ^ other._data)

    def is_subset(self, other: 'CustomSet[T]') -> bool:
        return self._data.issubset(other._data)

    def is_superset(self, other: 'CustomSet[T]') -> bool:
        return self._data.issuperset(other._data)

    def is_disjoint(self, other: 'CustomSet[T]') -> bool:
        return self._data.isdisjoint(other._data)

    def to_list(self) -> list:
        return list(self._data)

    def __iter__(self) -> Iterator[T]:
        return iter(self._data)

    def __len__(self) -> int:
        return len(self._data)

    def __contains__(self, element: T) -> bool:
        return element in self._data

    def __repr__(self) -> str:
        return f"CustomSet({self._data})"


class DisjointSet:
    def __init__(self, size: int):
        self.parent = list(range(size))
        self.rank = [0] * size

    def find(self, x: int) -> int:
        if self.parent[x] != x:
            self.parent[x] = self.find(self.parent[x])
        return self.parent[x]

    def union(self, x: int, y: int) -> bool:
        root_x = self.find(x)
        root_y = self.find(y)

        if root_x == root_y:
            return False

        if self.rank[root_x] < self.rank[root_y]:
            self.parent[root_x] = root_y
        elif self.rank[root_x] > self.rank[root_y]:
            self.parent[root_y] = root_x
        else:
            self.parent[root_y] = root_x
            self.rank[root_x] += 1

        return True

    def connected(self, x: int, y: int) -> bool:
        return self.find(x) == self.find(y)

    def count_components(self) -> int:
        return len(set(self.find(i) for i in range(len(self.parent))))
