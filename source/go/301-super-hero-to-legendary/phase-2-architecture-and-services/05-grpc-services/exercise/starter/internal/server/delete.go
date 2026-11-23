package server

// TODO 2: after regenerating the code, implement
//
//   func (s *Server) DeleteItem(ctx context.Context, req *inventoryv1.DeleteItemRequest) (*inventoryv1.DeleteItemResponse, error)
//
// Rules: an empty sku is codes.InvalidArgument; an unknown sku is
// codes.NotFound (same message style as GetItem); otherwise delete it under
// the write lock and answer Deleted: true.
//
// Until you do, the generated Unimplemented type answers codes.Unimplemented.
