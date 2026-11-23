package server

import (
	"context"
	"testing"

	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"

	inventoryv1 "example.com/code101/go301/l05/gen/inventory/v1"
)

func TestDeleteItem(t *testing.T) {
	client := newClient(t)
	ctx := context.Background()

	res, err := client.DeleteItem(ctx, &inventoryv1.DeleteItemRequest{Sku: "A-100"})
	if err != nil || !res.GetDeleted() {
		t.Fatalf("delete: res = %v, err = %v", res, err)
	}
	_, err = client.GetItem(ctx, &inventoryv1.GetItemRequest{Sku: "A-100"})
	if got := status.Code(err); got != codes.NotFound {
		t.Fatalf("after delete: code = %v, want NotFound", got)
	}
	_, err = client.DeleteItem(ctx, &inventoryv1.DeleteItemRequest{Sku: "A-100"})
	if got := status.Code(err); got != codes.NotFound {
		t.Fatalf("second delete: code = %v, want NotFound", got)
	}
}
