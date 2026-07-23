package broker

import (
	amqp "github.com/rabbitmq/amqp091-go"
	"go.uber.org/zap"
)

type Broker struct {
	conn    *amqp.Connection
	channel *amqp.Channel
	logger  *zap.Logger
}

func NewBroker(url string, logger *zap.Logger) (*Broker, error) {
	conn, err := amqp.Dial(url)
	if err != nil {
		return nil, err
	}

	ch, err := conn.Channel()
	if err != nil {
		conn.Close()
		return nil, err
	}

	return &Broker{
		conn:    conn,
		channel: ch,
		logger:  logger,
	}, nil
}

func (b *Broker) DeclareQueue(name string) error {
	_, err := b.channel.QueueDeclare(
		name,
		true,  // durable
		false, // delete when unused
		false, // exclusive
		false, // no-wait
		nil,   // arguments
	)
	return err
}

func (b *Broker) Channel() *amqp.Channel {
	return b.channel
}

func (b *Broker) Close() {
	if b.channel != nil {
		b.channel.Close()
	}
	if b.conn != nil {
		b.conn.Close()
	}
}
