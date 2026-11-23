package server

import (
	"context"

	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"

	inventoryv1 "example.com/code101/go301/l05/gen/inventory/v1"
)

// DeleteItem is a unary call that removes an item.
func (s *Server) DeleteItem(_ context.Context, req *inventoryv1.DeleteItemRequest) (*inventoryv1.DeleteItemResponse, error) {
	if req.GetSku() == "" {
		return nil, status.Error(codes.InvalidArgument, "sku is required")
	}
	s.mu.Lock()
	defer s.mu.Unlock()
	if _, ok := s.items[req.GetSku()]; !ok {
		return nil, status.Errorf(codes.NotFound, "item %q not found", req.GetSku())
	}
	delete(s.items, req.GetSku())
	return &inventoryv1.DeleteItemResponse{Deleted: true}, nil
}
