import asyncio
from typing import Any, Callable, List, Optional, TypeVar, Generic
from collections import defaultdict, deque
import time
from dataclasses import dataclass
from enum import Enum

T = TypeVar('T')
R = TypeVar('R')

class AsyncPool(Generic[T]):
    def __init__(self, max_size: int):
        self.max_size = max_size
        self.queue = asyncio.Queue()
        self.active = 0
        self.lock = asyncio.Lock()

    async def submit(self, coro):
        async with self.lock:
            while self.active >= self.max_size:
                await asyncio.sleep(0.01)
            self.active += 1

        try:
            result = await coro
            return result
        finally:
            async with self.lock:
                self.active -= 1

    async def map(self, func: Callable, items: List[Any]) -> List[Any]:
        tasks = [self.submit(func(item)) for item in items]
        return await asyncio.gather(*tasks)

class AsyncCache:
    def __init__(self, ttl: int = 300):
        self.cache = {}
        self.ttl = ttl
        self.lock = asyncio.Lock()

    async def get(self, key: str) -> Optional[Any]:
        async with self.lock:
            if key in self.cache:
                value, timestamp = self.cache[key]
                if time.time() - timestamp < self.ttl:
                    return value
                else:
                    del self.cache[key]
            return None

    async def set(self, key: str, value: Any):
        async with self.lock:
            self.cache[key] = (value, time.time())

    async def delete(self, key: str):
        async with self.lock:
            if key in self.cache:
                del self.cache[key]

    async def clear(self):
        async with self.lock:
            self.cache.clear()

    async def cleanup(self):
        async with self.lock:
            now = time.time()
            expired_keys = [
                k for k, (_, ts) in self.cache.items()
                if now - ts >= self.ttl
            ]
            for key in expired_keys:
                del self.cache[key]

class AsyncEventEmitter:
    def __init__(self):
        self.listeners = defaultdict(list)
        self.lock = asyncio.Lock()

    async def on(self, event: str, handler: Callable):
        async with self.lock:
            self.listeners[event].append(handler)

    async def off(self, event: str, handler: Callable = None):
        async with self.lock:
            if handler:
                if handler in self.listeners[event]:
                    self.listeners[event].remove(handler)
            else:
                self.listeners[event].clear()

    async def emit(self, event: str, *args, **kwargs):
        async with self.lock:
            handlers = self.listeners[event].copy()

        tasks = [handler(*args, **kwargs) for handler in handlers]
        await asyncio.gather(*tasks, return_exceptions=True)

    async def once(self, event: str, handler: Callable):
        async def wrapper(*args, **kwargs):
            await self.off(event, wrapper)
            await handler(*args, **kwargs)

        await self.on(event, wrapper)

class AsyncQueue(Generic[T]):
    def __init__(self, maxsize: int = 0):
        self.queue = asyncio.Queue(maxsize=maxsize)

    async def enqueue(self, item: T):
        await self.queue.put(item)

    async def dequeue(self) -> T:
        return await self.queue.get()

    async def dequeue_timeout(self, timeout: float) -> Optional[T]:
        try:
            return await asyncio.wait_for(self.queue.get(), timeout=timeout)
        except asyncio.TimeoutError:
            return None

    def size(self) -> int:
        return self.queue.qsize()

    def is_empty(self) -> bool:
        return self.queue.empty()

class AsyncRateLimiter:
    def __init__(self, max_calls: int, period: float):
        self.max_calls = max_calls
        self.period = period
        self.calls = deque()
        self.lock = asyncio.Lock()

    async def acquire(self):
        async with self.lock:
            now = time.time()

            while self.calls and self.calls[0] <= now - self.period:
                self.calls.popleft()

            if len(self.calls) >= self.max_calls:
                sleep_time = self.calls[0] + self.period - now
                await asyncio.sleep(sleep_time)
                return await self.acquire()

            self.calls.append(now)

    async def __aenter__(self):
        await self.acquire()
        return self

    async def __aexit__(self, exc_type, exc_val, exc_tb):
        pass

class AsyncCircuitBreaker:
    class State(Enum):
        CLOSED = "closed"
        OPEN = "open"
        HALF_OPEN = "half_open"

    def __init__(self, failure_threshold: int = 5, timeout: float = 60.0, success_threshold: int = 2):
        self.failure_threshold = failure_threshold
        self.timeout = timeout
        self.success_threshold = success_threshold
        self.failure_count = 0
        self.success_count = 0
        self.state = self.State.CLOSED
        self.last_failure_time = None
        self.lock = asyncio.Lock()

    async def call(self, func: Callable, *args, **kwargs):
        async with self.lock:
            if self.state == self.State.OPEN:
                if time.time() - self.last_failure_time >= self.timeout:
                    self.state = self.State.HALF_OPEN
                    self.success_count = 0
                else:
                    raise Exception("Circuit breaker is OPEN")

        try:
            result = await func(*args, **kwargs)

            async with self.lock:
                if self.state == self.State.HALF_OPEN:
                    self.success_count += 1
                    if self.success_count >= self.success_threshold:
                        self.state = self.State.CLOSED
                        self.failure_count = 0

            return result

        except Exception as e:
            async with self.lock:
                self.failure_count += 1
                self.last_failure_time = time.time()

                if self.failure_count >= self.failure_threshold:
                    self.state = self.State.OPEN

            raise e

class AsyncRetry:
    def __init__(self, max_attempts: int = 3, delay: float = 1.0, backoff: float = 2.0):
        self.max_attempts = max_attempts
        self.delay = delay
        self.backoff = backoff

    async def execute(self, func: Callable, *args, **kwargs):
        attempt = 0
        current_delay = self.delay

        while attempt < self.max_attempts:
            try:
                return await func(*args, **kwargs)
            except Exception as e:
                attempt += 1
                if attempt >= self.max_attempts:
                    raise e

                await asyncio.sleep(current_delay)
                current_delay *= self.backoff

class AsyncSemaphore:
    def __init__(self, value: int):
        self.semaphore = asyncio.Semaphore(value)

    async def acquire(self):
        await self.semaphore.acquire()

    def release(self):
        self.semaphore.release()

    async def __aenter__(self):
        await self.acquire()
        return self

    async def __aexit__(self, exc_type, exc_val, exc_tb):
        self.release()

class AsyncLock:
    def __init__(self):
        self.lock = asyncio.Lock()

    async def __aenter__(self):
        await self.lock.acquire()
        return self

    async def __aexit__(self, exc_type, exc_val, exc_tb):
        self.lock.release()

class AsyncBarrier:
    def __init__(self, parties: int):
        self.parties = parties
        self.count = 0
        self.event = asyncio.Event()
        self.lock = asyncio.Lock()

    async def wait(self):
        async with self.lock:
            self.count += 1
            if self.count >= self.parties:
                self.event.set()

        await self.event.wait()

        async with self.lock:
            self.count -= 1
            if self.count == 0:
                self.event.clear()

class AsyncBatcher:
    def __init__(self, batch_size: int, flush_interval: float):
        self.batch_size = batch_size
        self.flush_interval = flush_interval
        self.batch = []
        self.lock = asyncio.Lock()
        self.handler = None

    def on_batch(self, handler: Callable):
        self.handler = handler

    async def add(self, item: Any):
        async with self.lock:
            self.batch.append(item)
            if len(self.batch) >= self.batch_size:
                await self._flush()

    async def _flush(self):
        if self.batch and self.handler:
            batch_copy = self.batch.copy()
            self.batch.clear()
            await self.handler(batch_copy)

    async def start(self):
        while True:
            await asyncio.sleep(self.flush_interval)
            async with self.lock:
                await self._flush()

class AsyncDebouncer:
    def __init__(self, delay: float):
        self.delay = delay
        self.task = None
        self.lock = asyncio.Lock()

    async def call(self, func: Callable, *args, **kwargs):
        async with self.lock:
            if self.task:
                self.task.cancel()

            async def delayed_call():
                await asyncio.sleep(self.delay)
                await func(*args, **kwargs)

            self.task = asyncio.create_task(delayed_call())

class AsyncThrottler:
    def __init__(self, interval: float):
        self.interval = interval
        self.last_call = 0
        self.lock = asyncio.Lock()

    async def call(self, func: Callable, *args, **kwargs):
        async with self.lock:
            now = time.time()
            elapsed = now - self.last_call

            if elapsed < self.interval:
                await asyncio.sleep(self.interval - elapsed)

            self.last_call = time.time()
            return await func(*args, **kwargs)

class AsyncStream(Generic[T]):
    def __init__(self):
        self.subscribers = []
        self.lock = asyncio.Lock()

    async def subscribe(self, handler: Callable[[T], None]):
        async with self.lock:
            self.subscribers.append(handler)

    async def emit(self, value: T):
        async with self.lock:
            handlers = self.subscribers.copy()

        tasks = [handler(value) for handler in handlers]
        await asyncio.gather(*tasks, return_exceptions=True)

    def map(self, transform: Callable[[T], R]) -> 'AsyncStream[R]':
        stream = AsyncStream()

        async def handler(value):
            transformed = transform(value)
            await stream.emit(transformed)

        asyncio.create_task(self.subscribe(handler))
        return stream

    def filter(self, predicate: Callable[[T], bool]) -> 'AsyncStream[T]':
        stream = AsyncStream()

        async def handler(value):
            if predicate(value):
                await stream.emit(value)

        asyncio.create_task(self.subscribe(handler))
        return stream

class AsyncPipeline:
    def __init__(self):
        self.stages = []

    def add_stage(self, func: Callable):
        self.stages.append(func)
        return self

    async def execute(self, initial_value: Any) -> Any:
        value = initial_value
        for stage in self.stages:
            value = await stage(value)
        return value

class AsyncWorkerPool:
    def __init__(self, num_workers: int):
        self.num_workers = num_workers
        self.queue = asyncio.Queue()
        self.workers = []
        self.running = False

    async def _worker(self):
        while self.running:
            try:
                task = await asyncio.wait_for(self.queue.get(), timeout=1.0)
                func, args, kwargs = task
                await func(*args, **kwargs)
                self.queue.task_done()
            except asyncio.TimeoutError:
                continue

    async def start(self):
        self.running = True
        self.workers = [
            asyncio.create_task(self._worker())
            for _ in range(self.num_workers)
        ]

    async def stop(self):
        self.running = False
        await asyncio.gather(*self.workers)

    async def submit(self, func: Callable, *args, **kwargs):
        await self.queue.put((func, args, kwargs))

    async def wait_completion(self):
        await self.queue.join()
