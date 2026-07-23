use std::future::Future;
use std::pin::Pin;
use std::task::{Context, Poll};
use std::sync::{Arc, Mutex};
use std::collections::VecDeque;

pub struct SimpleExecutor {
    tasks: Arc<Mutex<VecDeque<Pin<Box<dyn Future<Output = ()> + Send>>>>>,
}

impl SimpleExecutor {
    pub fn new() -> Self {
        SimpleExecutor {
            tasks: Arc::new(Mutex::new(VecDeque::new())),
        }
    }

    pub fn spawn(&self, future: impl Future<Output = ()> + Send + 'static) {
        let mut tasks = self.tasks.lock().unwrap();
        tasks.push_back(Box::pin(future));
    }

    pub fn run(&self) {
        loop {
            let mut task = {
                let mut tasks = self.tasks.lock().unwrap();
                if tasks.is_empty() {
                    break;
                }
                tasks.pop_front().unwrap()
            };

            let waker = futures::task::noop_waker();
            let mut context = Context::from_waker(&waker);

            match task.as_mut().poll(&mut context) {
                Poll::Ready(_) => {}
                Poll::Pending => {
                    let mut tasks = self.tasks.lock().unwrap();
                    tasks.push_back(task);
                }
            }
        }
    }
}

pub struct Channel<T> {
    queue: Arc<Mutex<VecDeque<T>>>,
}

impl<T> Channel<T> {
    pub fn new() -> Self {
        Channel {
            queue: Arc::new(Mutex::new(VecDeque::new())),
        }
    }

    pub fn send(&self, value: T) {
        let mut queue = self.queue.lock().unwrap();
        queue.push_back(value);
    }

    pub fn recv(&self) -> Option<T> {
        let mut queue = self.queue.lock().unwrap();
        queue.pop_front()
    }

    pub fn len(&self) -> usize {
        let queue = self.queue.lock().unwrap();
        queue.len()
    }

    pub fn is_empty(&self) -> bool {
        let queue = self.queue.lock().unwrap();
        queue.is_empty()
    }
}

pub struct AsyncQueue<T> {
    items: Arc<Mutex<VecDeque<T>>>,
}

impl<T: Send> AsyncQueue<T> {
    pub fn new() -> Self {
        AsyncQueue {
            items: Arc::new(Mutex::new(VecDeque::new())),
        }
    }

    pub async fn push(&self, item: T) {
        let mut items = self.items.lock().unwrap();
        items.push_back(item);
    }

    pub async fn pop(&self) -> Option<T> {
        let mut items = self.items.lock().unwrap();
        items.pop_front()
    }

    pub fn len(&self) -> usize {
        let items = self.items.lock().unwrap();
        items.len()
    }
}

pub struct Promise<T> {
    value: Arc<Mutex<Option<T>>>,
}

impl<T> Promise<T> {
    pub fn new() -> Self {
        Promise {
            value: Arc::new(Mutex::new(None)),
        }
    }

    pub fn resolve(&self, value: T) {
        let mut val = self.value.lock().unwrap();
        *val = Some(value);
    }

    pub fn get(&self) -> Option<T>
    where
        T: Clone
    {
        let val = self.value.lock().unwrap();
        val.clone()
    }

    pub fn is_resolved(&self) -> bool {
        let val = self.value.lock().unwrap();
        val.is_some()
    }
}

pub struct Barrier {
    count: Arc<Mutex<usize>>,
    total: usize,
}

impl Barrier {
    pub fn new(total: usize) -> Self {
        Barrier {
            count: Arc::new(Mutex::new(0)),
            total,
        }
    }

    pub fn wait(&self) -> bool {
        let mut count = self.count.lock().unwrap();
        *count += 1;
        *count >= self.total
    }

    pub fn reset(&self) {
        let mut count = self.count.lock().unwrap();
        *count = 0;
    }

    pub fn arrived(&self) -> usize {
        let count = self.count.lock().unwrap();
        *count
    }
}
