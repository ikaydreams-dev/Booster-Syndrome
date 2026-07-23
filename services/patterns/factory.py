from abc import ABC, abstractmethod
from typing import Dict, Type, Any

class Product(ABC):
    @abstractmethod
    def operation(self) -> str:
        pass

class ConcreteProductA(Product):
    def operation(self) -> str:
        return "Result of ConcreteProductA"

class ConcreteProductB(Product):
    def operation(self) -> str:
        return "Result of ConcreteProductB"

class Factory(ABC):
    @abstractmethod
    def create_product(self) -> Product:
        pass

    def some_operation(self) -> str:
        product = self.create_product()
        return f"Factory: {product.operation()}"

class ConcreteFactoryA(Factory):
    def create_product(self) -> Product:
        return ConcreteProductA()

class ConcreteFactoryB(Factory):
    def create_product(self) -> Product:
        return ConcreteProductB()

class ProductRegistry:
    def __init__(self):
        self._creators: Dict[str, Type[Product]] = {}

    def register(self, key: str, creator: Type[Product]) -> None:
        self._creators[key] = creator

    def unregister(self, key: str) -> None:
        self._creators.pop(key, None)

    def create(self, key: str, **kwargs) -> Product:
        creator = self._creators.get(key)
        if not creator:
            raise ValueError(f"Unknown product type: {key}")
        return creator(**kwargs)

class Builder(ABC):
    @abstractmethod
    def reset(self) -> None:
        pass

    @abstractmethod
    def set_property_a(self, value: Any) -> 'Builder':
        pass

    @abstractmethod
    def set_property_b(self, value: Any) -> 'Builder':
        pass

    @abstractmethod
    def build(self) -> Any:
        pass

class ComplexObject:
    def __init__(self):
        self.property_a = None
        self.property_b = None
        self.property_c = None

    def __str__(self):
        return f"ComplexObject(a={self.property_a}, b={self.property_b}, c={self.property_c})"

class ComplexObjectBuilder(Builder):
    def __init__(self):
        self._object = ComplexObject()

    def reset(self) -> None:
        self._object = ComplexObject()

    def set_property_a(self, value: Any) -> 'ComplexObjectBuilder':
        self._object.property_a = value
        return self

    def set_property_b(self, value: Any) -> 'ComplexObjectBuilder':
        self._object.property_b = value
        return self

    def set_property_c(self, value: Any) -> 'ComplexObjectBuilder':
        self._object.property_c = value
        return self

    def build(self) -> ComplexObject:
        result = self._object
        self.reset()
        return result

class Singleton:
    _instances: Dict[Type, Any] = {}
    _lock = None

    def __new__(cls):
        if cls not in cls._instances:
            cls._instances[cls] = super().__new__(cls)
        return cls._instances[cls]

class Prototype(ABC):
    @abstractmethod
    def clone(self) -> 'Prototype':
        pass

class ConcretePrototype(Prototype):
    def __init__(self, value: Any):
        self.value = value

    def clone(self) -> 'ConcretePrototype':
        import copy
        return copy.deepcopy(self)

class ObjectPool:
    def __init__(self, creator, max_size=10):
        self._creator = creator
        self._max_size = max_size
        self._available = []
        self._in_use = set()

    def acquire(self):
        if self._available:
            obj = self._available.pop()
        elif len(self._in_use) < self._max_size:
            obj = self._creator()
        else:
            raise Exception("Pool exhausted")

        self._in_use.add(id(obj))
        return obj

    def release(self, obj):
        obj_id = id(obj)
        if obj_id in self._in_use:
            self._in_use.remove(obj_id)
            self._available.append(obj)

    def size(self):
        return len(self._available) + len(self._in_use)
