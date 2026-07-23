import asyncio
from typing import Callable, Dict, Any
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class BackgroundWorker:
    def __init__(self, name: str):
        self.name = name
        self.tasks: Dict[str, Callable] = {}
        self.running = False

    def register_task(self, task_name: str, handler: Callable):
        """Register a task handler"""
        self.tasks[task_name] = handler
        logger.info(f"Registered task: {task_name}")

    async def process_task(self, task_name: str, data: Any):
        """Process a single task"""
        handler = self.tasks.get(task_name)

        if not handler:
            logger.error(f"No handler found for task: {task_name}")
            return

        try:
            logger.info(f"Processing task: {task_name}")
            await handler(data)
            logger.info(f"Completed task: {task_name}")
        except Exception as e:
            logger.error(f"Error processing task {task_name}: {e}")

    async def start(self):
        """Start the worker"""
        self.running = True
        logger.info(f"Worker {self.name} started")

        while self.running:
            await asyncio.sleep(1)

    def stop(self):
        """Stop the worker"""
        self.running = False
        logger.info(f"Worker {self.name} stopped")

class WorkerPool:
    def __init__(self, num_workers: int = 4):
        self.workers = [BackgroundWorker(f"worker-{i}") for i in range(num_workers)]
        self.task_queue = asyncio.Queue()

    def register_task(self, task_name: str, handler: Callable):
        """Register a task handler on all workers"""
        for worker in self.workers:
            worker.register_task(task_name, handler)

    async def enqueue_task(self, task_name: str, data: Any):
        """Add task to queue"""
        await self.task_queue.put((task_name, data))

    async def process_queue(self):
        """Process tasks from the queue"""
        while True:
            task_name, data = await self.task_queue.get()

            worker = self.workers[0]
            await worker.process_task(task_name, data)

            self.task_queue.task_done()

async def email_handler(data: dict):
    """Handle email sending"""
    logger.info(f"Sending email to: {data.get('to')}")
    await asyncio.sleep(1)

async def analytics_handler(data: dict):
    """Handle analytics processing"""
    logger.info(f"Processing analytics event: {data.get('event_name')}")
    await asyncio.sleep(0.5)

async def notification_handler(data: dict):
    """Handle notification sending"""
    logger.info(f"Sending notification to user: {data.get('user_id')}")
    await asyncio.sleep(0.3)

worker_pool = WorkerPool(num_workers=4)
worker_pool.register_task('send_email', email_handler)
worker_pool.register_task('process_analytics', analytics_handler)
worker_pool.register_task('send_notification', notification_handler)
