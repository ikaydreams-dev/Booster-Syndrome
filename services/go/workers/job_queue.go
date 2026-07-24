package workers

import (
	"context"
	"sync"
)

type Job struct {
	ID      string
	Type    string
	Payload map[string]interface{}
}

type JobQueue struct {
	jobs    chan Job
	workers int
	wg      sync.WaitGroup
}

func NewJobQueue(workers int, bufferSize int) *JobQueue {
	return &JobQueue{
		jobs:    make(chan Job, bufferSize),
		workers: workers,
	}
}

func (jq *JobQueue) Start(ctx context.Context, processor func(Job) error) {
	for i := 0; i < jq.workers; i++ {
		jq.wg.Add(1)
		go jq.worker(ctx, processor)
	}
}

func (jq *JobQueue) worker(ctx context.Context, processor func(Job) error) {
	defer jq.wg.Done()
	
	for {
		select {
		case <-ctx.Done():
			return
		case job, ok := <-jq.jobs:
			if !ok {
				return
			}
			
			if err := processor(job); err != nil {
				// Log error
			}
		}
	}
}

func (jq *JobQueue) Enqueue(job Job) {
	jq.jobs <- job
}

func (jq *JobQueue) Stop() {
	close(jq.jobs)
	jq.wg.Wait()
}
