package queue

import (
	"encoding/json"
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
		return nil, err
	}

	channel, err := conn.Channel()
	if err != nil {
		return nil, err
	}

	return &RabbitMQHandler{
		conn:    conn,
		channel: channel,
	}, nil
}

func (r *RabbitMQHandler) DeclareQueue(name string) error {
	_, err := r.channel.QueueDeclare(
		name,
		true,
		false,
		false,
		false,
		nil,
	)
	return err
}

func (r *RabbitMQHandler) Publish(queueName string, message interface{}) error {
	body, err := json.Marshal(message)
	if err != nil {
		return err
	}

	return r.channel.Publish(
		"",
		queueName,
		false,
		false,
		amqp.Publishing{
			ContentType: "application/json",
			Body:        body,
		},
	)
}

func (r *RabbitMQHandler) Consume(queueName string, handler func([]byte) error) error {
	msgs, err := r.channel.Consume(
		queueName,
		"",
		false,
		false,
		false,
		false,
		nil,
	)
	if err != nil {
		return err
	}

	go func() {
		for msg := range msgs {
			if err := handler(msg.Body); err != nil {
				log.Printf("Error processing message: %v", err)
				msg.Nack(false, true)
			} else {
				msg.Ack(false)
			}
		}
	}()

	return nil
}

func (r *RabbitMQHandler) Close() {
	r.channel.Close()
	r.conn.Close()
}
