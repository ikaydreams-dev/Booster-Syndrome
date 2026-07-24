use std::sync::Arc;
use tokio::sync::Semaphore;
use tokio::task::JoinHandle;

pub struct TaskRunner {
    max_concurrent: usize,
}

impl TaskRunner {
    pub fn new(max_concurrent: usize) -> Self {
        Self { max_concurrent }
    }

    pub async fn run_tasks<F, Fut, T>(
        &self,
        tasks: Vec<F>,
    ) -> Vec<Result<T, tokio::task::JoinError>>
    where
        F: FnOnce() -> Fut + Send + 'static,
        Fut: std::future::Future<Output = T> + Send + 'static,
        T: Send + 'static,
    {
        let semaphore = Arc::new(Semaphore::new(self.max_concurrent));
        let mut handles: Vec<JoinHandle<T>> = Vec::new();

        for task in tasks {
            let permit = semaphore.clone().acquire_owned().await.unwrap();
            
            let handle = tokio::spawn(async move {
                let result = task().await;
                drop(permit);
                result
            });
            
            handles.push(handle);
        }

        let mut results = Vec::new();
        for handle in handles {
            results.push(handle.await);
        }

        results
    }

    pub async fn run_batch<F, Fut, T>(
        &self,
        items: Vec<T>,
        processor: F,
    ) -> Vec<Result<T, String>>
    where
        F: Fn(T) -> Fut + Send + Sync + 'static,
        Fut: std::future::Future<Output = Result<T, String>> + Send + 'static,
        T: Send + 'static,
    {
        let processor = Arc::new(processor);
        let semaphore = Arc::new(Semaphore::new(self.max_concurrent));
        let mut handles = Vec::new();

        for item in items {
            let processor = processor.clone();
            let permit = semaphore.clone().acquire_owned().await.unwrap();
            
            let handle = tokio::spawn(async move {
                let result = processor(item).await;
                drop(permit);
                result
            });
            
            handles.push(handle);
        }

        let mut results = Vec::new();
        for handle in handles {
            match handle.await {
                Ok(result) => results.push(result),
                Err(e) => results.push(Err(e.to_string())),
            }
        }

        results
    }
}
