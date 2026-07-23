package publisher

import (
	"context"
	"encoding/json"

	amqp "github.com/rabbitmq/amqp091-go"
	"go.uber.org/zap"

	"github.com/ikaydreams-dev/booster-syndrome/message-queue/pkg/broker"
)

type Publisher struct {
	broker *broker.Broker
	logger *zap.Logger
}

func NewPublisher(b *broker.Broker, logger *zap.Logger) *Publisher {
	return &Publisher{
		broker: b,
		logger: logger,
	}
}

func (p *Publisher) Publish(ctx context.Context, queue string, message interface{}) error {
	if err := p.broker.DeclareQueue(queue); err != nil {
		return err
	}

	body, err := json.Marshal(message)
	if err != nil {
		return err
	}

	err = p.broker.Channel().PublishWithContext(
		ctx,
		"",    // exchange
		queue, // routing key
		false, // mandatory
		false, // immediate
		amqp.Publishing{
			ContentType: "application/json",
			Body:        body,
		},
	)

	if err != nil {
		p.logger.Error("Failed to publish message", zap.Error(err))
		return err
	}

	p.logger.Info("Message published", zap.String("queue", queue))
	return nil
}
