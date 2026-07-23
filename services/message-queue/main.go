package main

import (
	"log"
	"os"
	"os/signal"
	"syscall"

	"github.com/joho/godotenv"
	"go.uber.org/zap"

	"github.com/ikaydreams-dev/booster-syndrome/message-queue/pkg/broker"
	"github.com/ikaydreams-dev/booster-syndrome/message-queue/pkg/consumer"
	"github.com/ikaydreams-dev/booster-syndrome/message-queue/pkg/publisher"
)

func main() {
	if err := godotenv.Load(); err != nil {
		log.Println("No .env file found")
	}

	logger, _ := zap.NewProduction()
	defer logger.Sync()

	rabbitURL := os.Getenv("RABBITMQ_URL")
	if rabbitURL == "" {
		rabbitURL = "amqp://guest:guest@localhost:5672/"
	}

	b, err := broker.NewBroker(rabbitURL, logger)
	if err != nil {
		logger.Fatal("Failed to create broker", zap.Error(err))
	}
	defer b.Close()

	pub := publisher.NewPublisher(b, logger)
	cons := consumer.NewConsumer(b, logger)

	go cons.Start()

	logger.Info("Message queue service started")

	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit

	logger.Info("Shutting down message queue service...")
}
