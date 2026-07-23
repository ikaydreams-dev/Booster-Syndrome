package grpc

import (
	"context"
	"log"

	pb "github.com/ikaydreams-dev/booster/proto"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
)

type UserServiceServer struct {
	pb.UnimplementedUserServiceServer
}

func (s *UserServiceServer) GetUser(ctx context.Context, req *pb.GetUserRequest) (*pb.User, error) {
	if req.Id == "" {
		return nil, status.Error(codes.InvalidArgument, "user id is required")
	}

	user := &pb.User{
		Id:        req.Id,
		Email:     "user@example.com",
		Username:  "testuser",
		FirstName: "Test",
		LastName:  "User",
		IsActive:  true,
	}

	return user, nil
}

func (s *UserServiceServer) CreateUser(ctx context.Context, req *pb.CreateUserRequest) (*pb.User, error) {
	if req.Email == "" || req.Username == "" {
		return nil, status.Error(codes.InvalidArgument, "email and username are required")
	}

	user := &pb.User{
		Id:        "generated-id",
		Email:     req.Email,
		Username:  req.Username,
		FirstName: req.FirstName,
		LastName:  req.LastName,
		IsActive:  true,
	}

	log.Printf("Created user: %s", user.Id)

	return user, nil
}

func (s *UserServiceServer) UpdateUser(ctx context.Context, req *pb.UpdateUserRequest) (*pb.User, error) {
	if req.Id == "" {
		return nil, status.Error(codes.InvalidArgument, "user id is required")
	}

	user := &pb.User{
		Id:        req.Id,
		Email:     req.Email,
		Username:  req.Username,
		FirstName: req.FirstName,
		LastName:  req.LastName,
		IsActive:  true,
	}

	return user, nil
}

type EventServiceServer struct {
	pb.UnimplementedEventServiceServer
}

func (s *EventServiceServer) TrackEvent(ctx context.Context, req *pb.TrackEventRequest) (*pb.EventResponse, error) {
	if req.UserId == "" || req.EventName == "" {
		return nil, status.Error(codes.InvalidArgument, "user_id and event_name are required")
	}

	log.Printf("Tracked event: %s for user: %s", req.EventName, req.UserId)

	return &pb.EventResponse{
		Success: true,
		EventId: "generated-event-id",
	}, nil
}

func (s *EventServiceServer) StreamEvents(req *pb.StreamEventsRequest, stream pb.EventService_StreamEventsServer) error {
	for i := 0; i < 10; i++ {
		event := &pb.Event{
			Id:         "event-id",
			UserId:     req.UserId,
			EventName:  "stream_event",
			EventType:  "analytics",
			Properties: make(map[string]string),
		}

		if err := stream.Send(event); err != nil {
			return err
		}
	}

	return nil
}
