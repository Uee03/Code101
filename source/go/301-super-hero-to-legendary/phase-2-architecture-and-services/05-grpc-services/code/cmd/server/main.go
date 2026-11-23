package main

import (
	"context"
	"log/slog"
	"net"
	"os"
	"os/signal"
	"syscall"
	"time"

	"google.golang.org/grpc"
	"google.golang.org/grpc/health"
	healthpb "google.golang.org/grpc/health/grpc_health_v1"
	"google.golang.org/grpc/status"

	inventoryv1 "example.com/code101/go301/l05/gen/inventory/v1"
	"example.com/code101/go301/l05/internal/server"
)

func main() {
	log := slog.New(slog.NewTextHandler(os.Stderr, nil))
	if err := run(log); err != nil {
		log.Error("server stopped", "error", err)
		os.Exit(1)
	}
}

func run(log *slog.Logger) error {
	addr := os.Getenv("GRPC_ADDR")
	if addr == "" {
		addr = "127.0.0.1:50051"
	}
	lis, err := net.Listen("tcp", addr)
	if err != nil {
		return err
	}

	srv := grpc.NewServer(
		grpc.MaxRecvMsgSize(1<<20),
		grpc.ChainUnaryInterceptor(logUnary(log)),
	)
	inventoryv1.RegisterInventoryServiceServer(srv, server.New(
		&inventoryv1.Item{Sku: "A-100", Name: "Widget", Quantity: 10},
		&inventoryv1.Item{Sku: "B-200", Name: "Gadget", Quantity: 0},
		&inventoryv1.Item{Sku: "C-300", Name: "Gizmo", Quantity: 5},
	))

	hs := health.NewServer()
	healthpb.RegisterHealthServer(srv, hs)
	hs.SetServingStatus("inventory.v1.InventoryService", healthpb.HealthCheckResponse_SERVING)

	ctx, stop := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
	defer stop()
	go func() {
		<-ctx.Done()
		hs.Shutdown()
		done := make(chan struct{})
		go func() {
			srv.GracefulStop()
			close(done)
		}()
		select {
		case <-done:
		case <-time.After(10 * time.Second):
			srv.Stop() // long-lived streams can block a graceful stop
		}
	}()

	log.Info("listening", "addr", addr)
	return srv.Serve(lis)
}

// logUnary logs every unary call with its status code and duration.
func logUnary(log *slog.Logger) grpc.UnaryServerInterceptor {
	return func(ctx context.Context, req any, info *grpc.UnaryServerInfo, handler grpc.UnaryHandler) (any, error) {
		start := time.Now()
		resp, err := handler(ctx, req)
		log.InfoContext(ctx, "rpc", "method", info.FullMethod, "code", status.Code(err).String(), "duration", time.Since(start))
		return resp, err
	}
}
