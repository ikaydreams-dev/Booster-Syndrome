package workers

import (
	"context"
	"time"
)

type ScheduledTask struct {
	Name     string
	Interval time.Duration
	Handler  func() error
}

type Scheduler struct {
	tasks  []ScheduledTask
	ctx    context.Context
	cancel context.CancelFunc
}

func NewScheduler() *Scheduler {
	ctx, cancel := context.WithCancel(context.Background())
	return &Scheduler{
		tasks:  make([]ScheduledTask, 0),
		ctx:    ctx,
		cancel: cancel,
	}
}

func (s *Scheduler) AddTask(task ScheduledTask) {
	s.tasks = append(s.tasks, task)
}

func (s *Scheduler) Start() {
	for _, task := range s.tasks {
		go s.runTask(task)
	}
}

func (s *Scheduler) runTask(task ScheduledTask) {
	ticker := time.NewTicker(task.Interval)
	defer ticker.Stop()

	for {
		select {
		case <-s.ctx.Done():
			return
		case <-ticker.C:
			if err := task.Handler(); err != nil {
				// Log error
			}
		}
	}
}

func (s *Scheduler) Stop() {
	s.cancel()
}
