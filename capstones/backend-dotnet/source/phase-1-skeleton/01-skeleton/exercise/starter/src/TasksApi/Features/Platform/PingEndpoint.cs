using FastEndpoints;

namespace TasksApi.Features.Platform;

public sealed record PingResponse(bool Pong);

// TODO 1: make this class an endpoint that has no request body and answers with a PingResponse
//         (derive from EndpointWithoutRequest<PingResponse>).
// TODO 2: add Configure(): answer GET /v1/ping and let anonymous callers in (AllowAnonymous).
// TODO 3: add HandleAsync(): send 200 OK with new PingResponse(true).
public sealed class PingEndpoint
{
}
