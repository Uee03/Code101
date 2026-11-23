using System.Text.Json;
using FastEndpoints;
using Microsoft.EntityFrameworkCore;
using TasksApi.Common;
using TasksApi.Contracts;
using TasksApi.Data;
using TasksApi.Security;

namespace TasksApi.Features.Audit;

public sealed class ListAuditRequest
{
    public string? EntityType { get; set; }
    public Guid? EntityId { get; set; }
    public Guid? ActorId { get; set; }
    public DateTimeOffset? From { get; set; }
    public DateTimeOffset? To { get; set; }
    public int? Limit { get; set; }
    public string? Cursor { get; set; }
}

// GET /v1/audit-log (admin): newest first. The trigger on each table wrote these rows; the API never writes them.
public sealed class ListAuditEndpoint(TasksDbContext db) : Endpoint<ListAuditRequest, Paged<AuditEntryDto>>
{
    private static readonly string[] EntityTypes = ["team", "member", "project", "task", "comment"];

    public override void Configure()
    {
        Get("/v1/audit-log");
        Policies(AccessPolicies.AdminOnly);
    }

    public override async Task HandleAsync(ListAuditRequest req, CancellationToken ct)
    {
        var limit = Paging.CheckLimit(req.Limit);
        if (req.EntityType is not null && !EntityTypes.Contains(req.EntityType))
        {
            throw ProblemException.BadRequest("entityType is not one of the allowed values.");
        }
        var query = db.AuditLog.AsNoTracking().AsQueryable();
        if (req.EntityType is not null)
        {
            query = query.Where(a => a.EntityType == req.EntityType);
        }
        if (req.EntityId is { } entityId)
        {
            query = query.Where(a => a.EntityId == entityId);
        }
        if (req.ActorId is { } actorId)
        {
            query = query.Where(a => a.ActorId == actorId);
        }
        if (req.From is { } from)
        {
            query = query.Where(a => a.OccurredAt >= from);
        }
        if (req.To is { } to)
        {
            query = query.Where(a => a.OccurredAt < to);
        }
        if (req.Cursor is not null)
        {
            if (!long.TryParse(Paging.Decode(req.Cursor).Id, out var before))
            {
                throw ProblemException.BadRequest("The cursor is not valid.");
            }
            query = query.Where(a => a.Id < before);
        }
        var page = await Paging.ToPageAsync(query.OrderByDescending(a => a.Id), limit, a => Paging.Encode(null, a.Id.ToString()),
            a => new AuditEntryDto(a.Id, a.OccurredAt, a.ActorId, a.Action, a.EntityType, a.EntityId,
                JsonDocument.Parse(a.Details).RootElement.Clone()), ct);
        await Send.OkAsync(page, ct);
    }
}
