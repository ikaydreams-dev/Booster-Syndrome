use std::sync::{Arc, Mutex, RwLock, Condvar};
use std::thread;
use std::time::Duration;
use std::collections::{HashMap, VecDeque};
use std::fs::{File, OpenOptions};
use std::io::{self, Read, Write, BufReader, BufWriter, Seek, SeekFrom};
use std::path::Path;

pub struct ThreadPool {
    workers: Vec<Worker>,
    sender: std::sync::mpsc::Sender<Job>,
}

type Job = Box<dyn FnOnce() + Send + 'static>;

struct Worker {
    id: usize,
    thread: Option<thread::JoinHandle<()>>,
}

impl ThreadPool {
    pub fn new(size: usize) -> ThreadPool {
        assert!(size > 0);

        let (sender, receiver) = std::sync::mpsc::channel();
        let receiver = Arc::new(Mutex::new(receiver));

        let mut workers = Vec::with_capacity(size);

        for id in 0..size {
            workers.push(Worker::new(id, Arc::clone(&receiver)));
        }

        ThreadPool { workers, sender }
    }

    pub fn execute<F>(&self, f: F)
    where
        F: FnOnce() + Send + 'static,
    {
        let job = Box::new(f);
        self.sender.send(job).unwrap();
    }
}

impl Drop for ThreadPool {
    fn drop(&mut self) {
        for worker in &mut self.workers {
            if let Some(thread) = worker.thread.take() {
                thread.join().unwrap();
            }
        }
    }
}

impl Worker {
    fn new(id: usize, receiver: Arc<Mutex<std::sync::mpsc::Receiver<Job>>>) -> Worker {
        let thread = thread::spawn(move || loop {
            let job = receiver.lock().unwrap().recv();

            match job {
                Ok(job) => {
                    job();
                }
                Err(_) => {
                    break;
                }
            }
        });

        Worker {
            id,
            thread: Some(thread),
        }
    }
}

pub struct Barrier {
    lock: Mutex<BarrierState>,
    cvar: Condvar,
    num_threads: usize,
}

struct BarrierState {
    count: usize,
    generation: usize,
}

impl Barrier {
    pub fn new(num_threads: usize) -> Barrier {
        Barrier {
            lock: Mutex::new(BarrierState {
                count: 0,
                generation: 0,
            }),
            cvar: Condvar::new(),
            num_threads,
        }
    }

    pub fn wait(&self) {
        let mut state = self.lock.lock().unwrap();
        let local_gen = state.generation;
        state.count += 1;

        if state.count < self.num_threads {
            while local_gen == state.generation {
                state = self.cvar.wait(state).unwrap();
            }
        } else {
            state.count = 0;
            state.generation = state.generation.wrapping_add(1);
            self.cvar.notify_all();
        }
    }
}

pub struct RwLockQueue<T> {
    queue: RwLock<VecDeque<T>>,
}

impl<T> RwLockQueue<T> {
    pub fn new() -> Self {
        RwLockQueue {
            queue: RwLock::new(VecDeque::new()),
        }
    }

    pub fn push(&self, item: T) {
        let mut queue = self.queue.write().unwrap();
        queue.push_back(item);
    }

    pub fn pop(&self) -> Option<T> {
        let mut queue = self.queue.write().unwrap();
        queue.pop_front()
    }

    pub fn len(&self) -> usize {
        let queue = self.queue.read().unwrap();
        queue.len()
    }

    pub fn is_empty(&self) -> bool {
        let queue = self.queue.read().unwrap();
        queue.is_empty()
    }
}

pub struct FileLogger {
    file: Mutex<BufWriter<File>>,
}

impl FileLogger {
    pub fn new(path: &Path) -> io::Result<Self> {
        let file = OpenOptions::new()
            .create(true)
            .append(true)
            .open(path)?;

        Ok(FileLogger {
            file: Mutex::new(BufWriter::new(file)),
        })
    }

    pub fn log(&self, message: &str) -> io::Result<()> {
        let mut file = self.file.lock().unwrap();
        writeln!(file, "{}", message)?;
        file.flush()?;
        Ok(())
    }

    pub fn log_with_timestamp(&self, message: &str) -> io::Result<()> {
        let timestamp = chrono::Local::now().format("%Y-%m-%d %H:%M:%S");
        let log_message = format!("[{}] {}", timestamp, message);
        self.log(&log_message)
    }
}

pub struct MemoryMappedFile {
    file: File,
    data: Vec<u8>,
    size: usize,
}

impl MemoryMappedFile {
    pub fn open(path: &Path) -> io::Result<Self> {
        let mut file = File::open(path)?;
        let metadata = file.metadata()?;
        let size = metadata.len() as usize;

        let mut data = vec![0; size];
        file.read_exact(&mut data)?;

        Ok(MemoryMappedFile { file, data, size })
    }

    pub fn read_at(&self, offset: usize, len: usize) -> &[u8] {
        let end = std::cmp::min(offset + len, self.size);
        &self.data[offset..end]
    }

    pub fn write_at(&mut self, offset: usize, data: &[u8]) -> io::Result<()> {
        let end = offset + data.len();
        if end > self.size {
            return Err(io::Error::new(
                io::ErrorKind::InvalidInput,
                "Write exceeds file size",
            ));
        }

        self.data[offset..end].copy_from_slice(data);
        self.file.seek(SeekFrom::Start(offset as u64))?;
        self.file.write_all(data)?;
        self.file.flush()?;

        Ok(())
    }

    pub fn size(&self) -> usize {
        self.size
    }
}

pub struct ProcessPool {
    workers: Vec<std::process::Child>,
}

impl ProcessPool {
    pub fn new(size: usize, command: &str, args: &[&str]) -> io::Result<Self> {
        let mut workers = Vec::with_capacity(size);

        for _ in 0..size {
            let child = std::process::Command::new(command)
                .args(args)
                .spawn()?;

            workers.push(child);
        }

        Ok(ProcessPool { workers })
    }

    pub fn wait_all(&mut self) -> io::Result<()> {
        for worker in &mut self.workers {
            worker.wait()?;
        }
        Ok(())
    }

    pub fn kill_all(&mut self) -> io::Result<()> {
        for worker in &mut self.workers {
            worker.kill()?;
        }
        Ok(())
    }
}

pub struct Cache<K: Eq + std::hash::Hash, V: Clone> {
    store: Mutex<HashMap<K, CacheEntry<V>>>,
    max_size: usize,
    ttl: Duration,
}

struct CacheEntry<V> {
    value: V,
    expires_at: std::time::Instant,
}

impl<K: Eq + std::hash::Hash, V: Clone> Cache<K, V> {
    pub fn new(max_size: usize, ttl: Duration) -> Self {
        Cache {
            store: Mutex::new(HashMap::new()),
            max_size,
            ttl,
        }
    }

    pub fn get(&self, key: &K) -> Option<V> {
        let mut store = self.store.lock().unwrap();

        if let Some(entry) = store.get(key) {
            if std::time::Instant::now() < entry.expires_at {
                return Some(entry.value.clone());
            } else {
                store.remove(key);
            }
        }

        None
    }

    pub fn put(&self, key: K, value: V) {
        let mut store = self.store.lock().unwrap();

        if store.len() >= self.max_size {
            if let Some(oldest_key) = store.keys().next().cloned() {
                store.remove(&oldest_key);
            }
        }

        store.insert(
            key,
            CacheEntry {
                value,
                expires_at: std::time::Instant::now() + self.ttl,
            },
        );
    }

    pub fn remove(&self, key: &K) {
        let mut store = self.store.lock().unwrap();
        store.remove(key);
    }

    pub fn clear(&self) {
        let mut store = self.store.lock().unwrap();
        store.clear();
    }
}

pub struct EventLoop {
    handlers: Mutex<HashMap<String, Vec<Box<dyn Fn() + Send>>>>,
    running: Arc<Mutex<bool>>,
}

impl EventLoop {
    pub fn new() -> Self {
        EventLoop {
            handlers: Mutex::new(HashMap::new()),
            running: Arc::new(Mutex::new(false)),
        }
    }

    pub fn on<F>(&self, event: &str, handler: F)
    where
        F: Fn() + Send + 'static,
    {
        let mut handlers = self.handlers.lock().unwrap();
        handlers
            .entry(event.to_string())
            .or_insert_with(Vec::new)
            .push(Box::new(handler));
    }

    pub fn emit(&self, event: &str) {
        let handlers = self.handlers.lock().unwrap();

        if let Some(event_handlers) = handlers.get(event) {
            for handler in event_handlers {
                handler();
            }
        }
    }

    pub fn run(&self) {
        let mut running = self.running.lock().unwrap();
        *running = true;
        drop(running);

        loop {
            let running = self.running.lock().unwrap();
            if !*running {
                break;
            }
            drop(running);

            thread::sleep(Duration::from_millis(10));
        }
    }

    pub fn stop(&self) {
        let mut running = self.running.lock().unwrap();
        *running = false;
    }
}

pub struct Signal {
    value: Mutex<bool>,
    cvar: Condvar,
}

impl Signal {
    pub fn new() -> Self {
        Signal {
            value: Mutex::new(false),
            cvar: Condvar::new(),
        }
    }

    pub fn notify(&self) {
        let mut value = self.value.lock().unwrap();
        *value = true;
        self.cvar.notify_all();
    }

    pub fn wait(&self) {
        let mut value = self.value.lock().unwrap();
        while !*value {
            value = self.cvar.wait(value).unwrap();
        }
        *value = false;
    }

    pub fn wait_timeout(&self, timeout: Duration) -> bool {
        let mut value = self.value.lock().unwrap();

        if !*value {
            let result = self.cvar.wait_timeout(value, timeout).unwrap();
            value = result.0;
        }

        let signaled = *value;
        if signaled {
            *value = false;
        }
        signaled
    }
}

pub struct Pipeline<T> {
    stages: Vec<Box<dyn Fn(T) -> T + Send>>,
}

impl<T: Send + 'static> Pipeline<T> {
    pub fn new() -> Self {
        Pipeline {
            stages: Vec::new(),
        }
    }

    pub fn add_stage<F>(&mut self, stage: F)
    where
        F: Fn(T) -> T + Send + 'static,
    {
        self.stages.push(Box::new(stage));
    }

    pub fn execute(&self, input: T) -> T {
        self.stages.iter().fold(input, |acc, stage| stage(acc))
    }
}
