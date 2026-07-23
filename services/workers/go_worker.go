package workers

import (
	"context"
	"fmt"
	"log"
	"sync"
	"time"
)

type Task struct {
	Name string
	Data interface{}
}

type TaskHandler func(context.Context, interface{}) error

type Worker struct {
	id       int
	taskChan chan Task
	handlers map[string]TaskHandler
	wg       *sync.WaitGroup
}

func NewWorker(id int, taskChan chan Task, wg *sync.WaitGroup) *Worker {
	return &Worker{
		id:       id,
		taskChan: taskChan,
		handlers: make(map[string]TaskHandler),
		wg:       wg,
	}
}

func (w *Worker) RegisterHandler(taskName string, handler TaskHandler) {
	w.handlers[taskName] = handler
}

func (w *Worker) Start(ctx context.Context) {
	defer w.wg.Done()

	for {
		select {
		case task := <-w.taskChan:
			w.processTask(ctx, task)
		case <-ctx.Done():
			log.Printf("Worker %d stopping", w.id)
			return
		}
	}
}

func (w *Worker) processTask(ctx context.Context, task Task) {
	handler, exists := w.handlers[task.Name]

	if !exists {
		log.Printf("Worker %d: No handler for task %s", w.id, task.Name)
		return
	}

	log.Printf("Worker %d: Processing task %s", w.id, task.Name)

	if err := handler(ctx, task.Data); err != nil {
		log.Printf("Worker %d: Error processing task %s: %v", w.id, task.Name, err)
	} else {
		log.Printf("Worker %d: Completed task %s", w.id, task.Name)
	}
}

type WorkerPool struct {
	workers  []*Worker
	taskChan chan Task
	wg       *sync.WaitGroup
	ctx      context.Context
	cancel   context.CancelFunc
}

func NewWorkerPool(numWorkers int, bufferSize int) *WorkerPool {
	taskChan := make(chan Task, bufferSize)
	wg := &sync.WaitGroup{}
	ctx, cancel := context.WithCancel(context.Background())

	workers := make([]*Worker, numWorkers)
	for i := 0; i < numWorkers; i++ {
		workers[i] = NewWorker(i, taskChan, wg)
	}

	return &WorkerPool{
		workers:  workers,
		taskChan: taskChan,
		wg:       wg,
		ctx:      ctx,
		cancel:   cancel,
	}
}

func (p *WorkerPool) RegisterHandler(taskName string, handler TaskHandler) {
	for _, worker := range p.workers {
		worker.RegisterHandler(taskName, handler)
	}
}

func (p *WorkerPool) Start() {
	for _, worker := range p.workers {
		p.wg.Add(1)
		go worker.Start(p.ctx)
	}

	log.Printf("Worker pool started with %d workers", len(p.workers))
}

func (p *WorkerPool) Submit(task Task) {
	p.taskChan <- task
}

func (p *WorkerPool) Stop() {
	close(p.taskChan)
	p.cancel()
	p.wg.Wait()

	log.Println("Worker pool stopped")
}

func EmailHandler(ctx context.Context, data interface{}) error {
	email := data.(map[string]interface{})
	fmt.Printf("Sending email to: %v\n", email["to"])
	time.Sleep(1 * time.Second)
	return nil
}

func AnalyticsHandler(ctx context.Context, data interface{}) error {
	event := data.(map[string]interface{})
	fmt.Printf("Processing analytics event: %v\n", event["event_name"])
	time.Sleep(500 * time.Millisecond)
	return nil
}

func NotificationHandler(ctx context.Context, data interface{}) error {
	notification := data.(map[string]interface{})
	fmt.Printf("Sending notification to user: %v\n", notification["user_id"])
	time.Sleep(300 * time.Millisecond)
	return nil
}
