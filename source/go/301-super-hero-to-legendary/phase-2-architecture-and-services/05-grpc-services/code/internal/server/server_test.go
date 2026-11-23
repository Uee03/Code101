package server

import (
	"context"
	"errors"
	"io"
	"net"
	"testing"

	"google.golang.org/grpc"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/credentials/insecure"
	"google.golang.org/grpc/status"
	"google.golang.org/grpc/test/bufconn"

	inventoryv1 "example.com/code101/go301/l05/gen/inventory/v1"
)

func seed() []*inventoryv1.Item {
	return []*inventoryv1.Item{
		{Sku: "A-100", Name: "Widget", Quantity: 10},
		{Sku: "B-200", Name: "Gadget", Quantity: 0},
		{Sku: "C-300", Name: "Gizmo", Quantity: 5},
	}
}

// newClient starts the server on an in-memory connection: a real gRPC stack
// (framing, status codes, streaming) without a network port.
func newClient(t *testing.T) inventoryv1.InventoryServiceClient {
	t.Helper()
	lis := bufconn.Listen(1 << 20)
	srv := grpc.NewServer()
	inventoryv1.RegisterInventoryServiceServer(srv, New(seed()...))
	go func() { _ = srv.Serve(lis) }()
	t.Cleanup(srv.Stop)

	conn, err := grpc.NewClient("passthrough:///bufnet",
		grpc.WithContextDialer(func(ctx context.Context, _ string) (net.Conn, error) {
			return lis.DialContext(ctx)
		}),
		grpc.WithTransportCredentials(insecure.NewCredentials()),
	)
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() { _ = conn.Close() })
	return inventoryv1.NewInventoryServiceClient(conn)
}

func TestGetItemNotFound(t *testing.T) {
	client := newClient(t)

	_, err := client.GetItem(context.Background(), &inventoryv1.GetItemRequest{Sku: "nope"})
	if got := status.Code(err); got != codes.NotFound {
		t.Fatalf("code = %v, want NotFound (err: %v)", got, err)
	}
}

func TestListItemsFiltersByMinQuantity(t *testing.T) {
	client := newClient(t)

	stream, err := client.ListItems(context.Background(), &inventoryv1.ListItemsRequest{MinQuantity: 1})
	if err != nil {
		t.Fatal(err)
	}
	var skus []string
	for {
		msg, err := stream.Recv()
		if errors.Is(err, io.EOF) {
			break
		}
		if err != nil {
			t.Fatal(err)
		}
		skus = append(skus, msg.GetItem().GetSku())
	}
	if len(skus) != 2 || skus[0] != "A-100" || skus[1] != "C-300" {
		t.Fatalf("skus = %v, want [A-100 C-300]", skus)
	}
}

func TestUploadStockRejectsNegativeResult(t *testing.T) {
	client := newClient(t)

	up, err := client.UploadStock(context.Background())
	if err != nil {
		t.Fatal(err)
	}
	if err := up.Send(&inventoryv1.UploadStockRequest{Sku: "C-300", Delta: -99}); err != nil {
		t.Fatal(err)
	}
	_, err = up.CloseAndRecv()
	if got := status.Code(err); got != codes.FailedPrecondition {
		t.Fatalf("code = %v, want FailedPrecondition (err: %v)", got, err)
	}
}
