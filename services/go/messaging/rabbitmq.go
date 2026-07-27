package messaging

import (
	"encoding/json"
	"fmt"
	"log"

	"github.com/streadway/amqp"
)

type RabbitMQHandler struct {
	conn    *amqp.Connection
	channel *amqp.Channel
}

func NewRabbitMQHandler(url string) (*RabbitMQHandler, error) {
	conn, err := amqp.Dial(url)
	if err != nil {
		return nil, fmt.Errorf("failed to connect to RabbitMQ: %w", err)
	}

	ch, err := conn.Channel()
	if err != nil {
		conn.Close()
		return nil, fmt.Errorf("failed to open channel: %w", err)
	}

	return &RabbitMQHandler{
		conn:    conn,
		channel: ch,
	}, nil
}

func (h *RabbitMQHandler) DeclareQueue(name string) error {
	_, err := h.channel.QueueDeclare(
		name,  // name
		true,  // durable
		false, // delete when unused
		false, // exclusive
		false, // no-wait
		nil,   // arguments
	)
	return err
}

func (h *RabbitMQHandler) Publish(queueName string, message interface{}) error {
	body, err := json.Marshal(message)
	if err != nil {
		return fmt.Errorf("failed to marshal message: %w", err)
	}

	err = h.channel.Publish(
		"",        // exchange
		queueName, // routing key
		false,     // mandatory
		false,     // immediate
		amqp.Publishing{
			DeliveryMode: amqp.Persistent,
			ContentType:  "application/json",
			Body:         body,
		},
	)
	
	if err != nil {
		return fmt.Errorf("failed to publish message: %w", err)
	}

	return nil
}

func (h *RabbitMQHandler) Consume(queueName string, handler func([]byte) error) error {
	msgs, err := h.channel.Consume(
		queueName, // queue
		"",        // consumer
		false,     // auto-ack
		false,     // exclusive
		false,     // no-local
		false,     // no-wait
		nil,       // args
	)
	if err != nil {
		return fmt.Errorf("failed to register consumer: %w", err)
	}

	go func() {
		for msg := range msgs {
			if err := handler(msg.Body); err != nil {
				log.Printf("Error handling message: %v", err)
				msg.Nack(false, true) // Requeue on error
			} else {
				msg.Ack(false)
			}
		}
	}()

	return nil
}

func (h *RabbitMQHandler) Close() error {
	if err := h.channel.Close(); err != nil {
		return err
	}
	return h.conn.Close()
}
