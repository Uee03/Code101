package server

import (
	"cmp"
	"context"
	"errors"
	"io"
	"slices"
	"sync"

	"google.golang.org/grpc"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"

	inventoryv1 "example.com/code101/go301/l05/gen/inventory/v1"
)

type stock struct {
	name     string
	quantity int32
}

// Server implements inventoryv1.InventoryServiceServer. Embedding the
// Unimplemented type by value is required by the generated code: methods
// added to the proto later return codes.Unimplemented instead of breaking the build.
type Server struct {
	inventoryv1.UnimplementedInventoryServiceServer

	mu    sync.RWMutex
	items map[string]stock
}

// New creates a server pre-loaded with items.
func New(seed ...*inventoryv1.Item) *Server {
	s := &Server{items: make(map[string]stock, len(seed))}
	for _, it := range seed {
		s.items[it.GetSku()] = stock{name: it.GetName(), quantity: it.GetQuantity()}
	}
	return s
}

// GetItem is a unary call.
func (s *Server) GetItem(_ context.Context, req *inventoryv1.GetItemRequest) (*inventoryv1.GetItemResponse, error) {
	if req.GetSku() == "" {
		return nil, status.Error(codes.InvalidArgument, "sku is required")
	}
	item, ok := s.lookup(req.GetSku())
	if !ok {
		return nil, status.Errorf(codes.NotFound, "item %q not found", req.GetSku())
	}
	return &inventoryv1.GetItemResponse{Item: item}, nil
}

// ListItems is server streaming: it sends one message per matching item, in
// SKU order, and stops early when the client cancels.
func (s *Server) ListItems(req *inventoryv1.ListItemsRequest, stream grpc.ServerStreamingServer[inventoryv1.ListItemsResponse]) error {
	for _, item := range s.snapshot() {
		if item.GetQuantity() < req.GetMinQuantity() {
			continue
		}
		if err := stream.Context().Err(); err != nil {
			return status.FromContextError(err).Err()
		}
		if err := stream.Send(&inventoryv1.ListItemsResponse{Item: item}); err != nil {
			return err
		}
	}
	return nil
}

// UploadStock is client streaming. Each message is applied as it arrives, so a
// failure half-way leaves the earlier changes in place (not transactional).
func (s *Server) UploadStock(stream grpc.ClientStreamingServer[inventoryv1.UploadStockRequest, inventoryv1.UploadStockResponse]) error {
	var updated int32
	for {
		req, err := stream.Recv()
		if errors.Is(err, io.EOF) {
			return stream.SendAndClose(&inventoryv1.UploadStockResponse{Updated: updated})
		}
		if err != nil {
			return err
		}
		if err := s.adjust(req.GetSku(), req.GetDelta()); err != nil {
			return err
		}
		updated++
	}
}

// CheckStock is bidirectional streaming: it answers each request as it arrives.
func (s *Server) CheckStock(stream grpc.BidiStreamingServer[inventoryv1.CheckStockRequest, inventoryv1.CheckStockResponse]) error {
	for {
		req, err := stream.Recv()
		if errors.Is(err, io.EOF) {
			return nil
		}
		if err != nil {
			return err
		}
		resp := &inventoryv1.CheckStockResponse{Sku: req.GetSku()}
		if item, ok := s.lookup(req.GetSku()); ok {
			resp.Quantity = item.GetQuantity()
			resp.Found = true
		}
		if err := stream.Send(resp); err != nil {
			return err
		}
	}
}

func (s *Server) lookup(sku string) (*inventoryv1.Item, bool) {
	s.mu.RLock()
	defer s.mu.RUnlock()
	st, ok := s.items[sku]
	if !ok {
		return nil, false
	}
	return &inventoryv1.Item{Sku: sku, Name: st.name, Quantity: st.quantity}, true
}

func (s *Server) snapshot() []*inventoryv1.Item {
	s.mu.RLock()
	defer s.mu.RUnlock()
	out := make([]*inventoryv1.Item, 0, len(s.items))
	for sku, st := range s.items {
		out = append(out, &inventoryv1.Item{Sku: sku, Name: st.name, Quantity: st.quantity})
	}
	slices.SortFunc(out, func(a, b *inventoryv1.Item) int { return cmp.Compare(a.GetSku(), b.GetSku()) })
	return out
}

func (s *Server) adjust(sku string, delta int32) error {
	s.mu.Lock()
	defer s.mu.Unlock()
	st, ok := s.items[sku]
	if !ok {
		return status.Errorf(codes.NotFound, "item %q not found", sku)
	}
	if st.quantity+delta < 0 {
		return status.Errorf(codes.FailedPrecondition, "item %q would go below zero", sku)
	}
	st.quantity += delta
	s.items[sku] = st
	return nil
}
