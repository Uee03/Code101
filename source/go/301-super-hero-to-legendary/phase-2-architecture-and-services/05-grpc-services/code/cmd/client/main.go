package main

import (
	"context"
	"errors"
	"fmt"
	"io"
	"os"
	"time"

	"google.golang.org/grpc"
	"google.golang.org/grpc/credentials/insecure"
	"google.golang.org/grpc/status"

	inventoryv1 "example.com/code101/go301/l05/gen/inventory/v1"
)

func main() {
	if err := run(); err != nil {
		fmt.Fprintln(os.Stderr, "error:", err)
		os.Exit(1)
	}
}

func run() error {
	addr := os.Getenv("GRPC_ADDR")
	if addr == "" {
		addr = "127.0.0.1:50051"
	}
	// Plaintext is for this local lesson only; lesson 08 adds TLS.
	conn, err := grpc.NewClient(addr, grpc.WithTransportCredentials(insecure.NewCredentials()))
	if err != nil {
		return err
	}
	defer conn.Close()
	client := inventoryv1.NewInventoryServiceClient(conn)

	// Every call shares one deadline: if the whole sequence is slower than this, it fails.
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	res, err := client.GetItem(ctx, &inventoryv1.GetItemRequest{Sku: "A-100"})
	if err != nil {
		return err
	}
	fmt.Printf("GetItem A-100: %s qty=%d\n", res.GetItem().GetName(), res.GetItem().GetQuantity())

	_, err = client.GetItem(ctx, &inventoryv1.GetItemRequest{Sku: "Z-999"})
	fmt.Printf("GetItem Z-999: code=%s message=%s\n", status.Code(err), status.Convert(err).Message())

	list, err := client.ListItems(ctx, &inventoryv1.ListItemsRequest{MinQuantity: 1})
	if err != nil {
		return err
	}
	for {
		msg, err := list.Recv()
		if errors.Is(err, io.EOF) {
			break
		}
		if err != nil {
			return err
		}
		fmt.Printf("ListItems: %s %s qty=%d\n", msg.GetItem().GetSku(), msg.GetItem().GetName(), msg.GetItem().GetQuantity())
	}

	up, err := client.UploadStock(ctx)
	if err != nil {
		return err
	}
	for _, change := range []struct {
		sku   string
		delta int32
	}{{"A-100", 5}, {"C-300", -2}} {
		if err := up.Send(&inventoryv1.UploadStockRequest{Sku: change.sku, Delta: change.delta}); err != nil {
			return err
		}
	}
	summary, err := up.CloseAndRecv()
	if err != nil {
		return err
	}
	fmt.Printf("UploadStock: updated %d items\n", summary.GetUpdated())

	chk, err := client.CheckStock(ctx)
	if err != nil {
		return err
	}
	for _, sku := range []string{"A-100", "B-200", "Q-000"} {
		if err := chk.Send(&inventoryv1.CheckStockRequest{Sku: sku}); err != nil {
			return err
		}
		r, err := chk.Recv()
		if err != nil {
			return err
		}
		fmt.Printf("CheckStock: %s found=%t qty=%d\n", r.GetSku(), r.GetFound(), r.GetQuantity())
	}
	return chk.CloseSend()
}
