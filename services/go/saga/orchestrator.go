package saga

import (
	"context"
	"fmt"
	"time"
)

type SagaStep struct {
	Name         string
	Action       func(ctx context.Context, data interface{}) error
	Compensation func(ctx context.Context, data interface{}) error
}

type SagaOrchestrator struct {
	steps      []SagaStep
	executed   []int
	sagaData   interface{}
}

func NewSagaOrchestrator(data interface{}) *SagaOrchestrator {
	return &SagaOrchestrator{
		steps:    make([]SagaStep, 0),
		executed: make([]int, 0),
		sagaData: data,
	}
}

func (s *SagaOrchestrator) AddStep(step SagaStep) {
	s.steps = append(s.steps, step)
}

func (s *SagaOrchestrator) Execute(ctx context.Context) error {
	for i, step := range s.steps {
		if err := step.Action(ctx, s.sagaData); err != nil {
			// Compensate all executed steps in reverse order
			if compensateErr := s.compensate(ctx); compensateErr != nil {
				return fmt.Errorf("saga failed at step %s and compensation failed: %w (original: %v)", 
					step.Name, compensateErr, err)
			}
			return fmt.Errorf("saga failed at step %s: %w", step.Name, err)
		}
		s.executed = append(s.executed, i)
	}
	return nil
}

func (s *SagaOrchestrator) compensate(ctx context.Context) error {
	// Execute compensations in reverse order
	for i := len(s.executed) - 1; i >= 0; i-- {
		stepIndex := s.executed[i]
		step := s.steps[stepIndex]
		
		if step.Compensation != nil {
			if err := step.Compensation(ctx, s.sagaData); err != nil {
				return fmt.Errorf("compensation failed for step %s: %w", step.Name, err)
			}
		}
	}
	return nil
}

// Example: Order Saga
type OrderSagaData struct {
	OrderID   string
	UserID    string
	ProductID string
	Amount    float64
	Reserved  bool
	Charged   bool
}

func CreateOrderSaga(data *OrderSagaData) *SagaOrchestrator {
	saga := NewSagaOrchestrator(data)

	// Step 1: Reserve inventory
	saga.AddStep(SagaStep{
		Name: "ReserveInventory",
		Action: func(ctx context.Context, d interface{}) error {
			orderData := d.(*OrderSagaData)
			fmt.Printf("Reserving inventory for product %s\n", orderData.ProductID)
			orderData.Reserved = true
			return nil
		},
		Compensation: func(ctx context.Context, d interface{}) error {
			orderData := d.(*OrderSagaData)
			fmt.Printf("Releasing inventory for product %s\n", orderData.ProductID)
			orderData.Reserved = false
			return nil
		},
	})

	// Step 2: Charge payment
	saga.AddStep(SagaStep{
		Name: "ChargePayment",
		Action: func(ctx context.Context, d interface{}) error {
			orderData := d.(*OrderSagaData)
			fmt.Printf("Charging $%.2f from user %s\n", orderData.Amount, orderData.UserID)
			orderData.Charged = true
			return nil
		},
		Compensation: func(ctx context.Context, d interface{}) error {
			orderData := d.(*OrderSagaData)
			fmt.Printf("Refunding $%.2f to user %s\n", orderData.Amount, orderData.UserID)
			orderData.Charged = false
			return nil
		},
	})

	// Step 3: Create order
	saga.AddStep(SagaStep{
		Name: "CreateOrder",
		Action: func(ctx context.Context, d interface{}) error {
			orderData := d.(*OrderSagaData)
			fmt.Printf("Creating order %s\n", orderData.OrderID)
			return nil
		},
		Compensation: func(ctx context.Context, d interface{}) error {
			orderData := d.(*OrderSagaData)
			fmt.Printf("Canceling order %s\n", orderData.OrderID)
			return nil
		},
	})

	return saga
}
