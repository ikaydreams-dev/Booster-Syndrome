package consumer

import (
	"go.uber.org/zap"

	"github.com/ikaydreams-dev/booster-syndrome/message-queue/pkg/broker"
)

type Consumer struct {
	broker *broker.Broker
	logger *zap.Logger
}

func NewConsumer(b *broker.Broker, logger *zap.Logger) *Consumer {
	return &Consumer{
		broker: b,
		logger: logger,
	}
}

func (c *Consumer) Start() {
	queues := []string{"events", "notifications", "analytics"}

	for _, queue := range queues {
		if err := c.broker.DeclareQueue(queue); err != nil {
			c.logger.Error("Failed to declare queue", zap.String("queue", queue), zap.Error(err))
			continue
		}

		msgs, err := c.broker.Channel().Consume(
			queue,
			"",    // consumer
			true,  // auto-ack
			false, // exclusive
			false, // no-local
			false, // no-wait
			nil,   // args
		)

		if err != nil {
			c.logger.Error("Failed to register consumer", zap.String("queue", queue), zap.Error(err))
			continue
		}

		go func(q string) {
			for msg := range msgs {
				c.logger.Info("Received message",
					zap.String("queue", q),
					zap.ByteString("body", msg.Body))
			}
		}(queue)
	}
}
