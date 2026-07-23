package signals

import "sync"

type Event struct {
	Type string
	Data interface{}
}

type Observer interface {
	OnNotify(event Event)
}

type Subject struct {
	mu        sync.RWMutex
	observers map[string][]Observer
}

func NewSubject() *Subject {
	return &Subject{
		observers: make(map[string][]Observer),
	}
}

func (s *Subject) Subscribe(eventType string, observer Observer) {
	s.mu.Lock()
	defer s.mu.Unlock()

	s.observers[eventType] = append(s.observers[eventType], observer)
}

func (s *Subject) Unsubscribe(eventType string, observer Observer) {
	s.mu.Lock()
	defer s.mu.Unlock()

	observers := s.observers[eventType]
	for i, obs := range observers {
		if obs == observer {
			s.observers[eventType] = append(observers[:i], observers[i+1:]...)
			break
		}
	}
}

func (s *Subject) Notify(event Event) {
	s.mu.RLock()
	observers := make([]Observer, len(s.observers[event.Type]))
	copy(observers, s.observers[event.Type])
	s.mu.RUnlock()

	for _, observer := range observers {
		go observer.OnNotify(event)
	}
}

func (s *Subject) NotifySync(event Event) {
	s.mu.RLock()
	observers := make([]Observer, len(s.observers[event.Type]))
	copy(observers, s.observers[event.Type])
	s.mu.RUnlock()

	for _, observer := range observers {
		observer.OnNotify(event)
	}
}

func (s *Subject) Clear(eventType string) {
	s.mu.Lock()
	defer s.mu.Unlock()

	delete(s.observers, eventType)
}

func (s *Subject) ClearAll() {
	s.mu.Lock()
	defer s.mu.Unlock()

	s.observers = make(map[string][]Observer)
}

type EventBus struct {
	channels map[string][]chan Event
	mu       sync.RWMutex
}

func NewEventBus() *EventBus {
	return &EventBus{
		channels: make(map[string][]chan Event),
	}
}

func (eb *EventBus) Subscribe(eventType string) <-chan Event {
	eb.mu.Lock()
	defer eb.mu.Unlock()

	ch := make(chan Event, 100)
	eb.channels[eventType] = append(eb.channels[eventType], ch)
	return ch
}

func (eb *EventBus) Publish(event Event) {
	eb.mu.RLock()
	channels := make([]chan Event, len(eb.channels[event.Type]))
	copy(channels, eb.channels[event.Type])
	eb.mu.RUnlock()

	for _, ch := range channels {
		go func(c chan Event) {
			c <- event
		}(ch)
	}
}

func (eb *EventBus) PublishSync(event Event) {
	eb.mu.RLock()
	channels := make([]chan Event, len(eb.channels[event.Type]))
	copy(channels, eb.channels[event.Type])
	eb.mu.RUnlock()

	for _, ch := range channels {
		ch <- event
	}
}

func (eb *EventBus) Close(eventType string) {
	eb.mu.Lock()
	defer eb.mu.Unlock()

	for _, ch := range eb.channels[eventType] {
		close(ch)
	}
	delete(eb.channels, eventType)
}
