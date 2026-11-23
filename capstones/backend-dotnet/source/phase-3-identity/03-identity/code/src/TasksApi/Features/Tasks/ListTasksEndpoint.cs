using FastEndpoints;
using Microsoft.EntityFrameworkCore;
using TasksApi.Common;
using TasksApi.Contracts;
using TasksApi.Data;
using TasksApi.Security;

namespace TasksApi.Features.Tasks;

public sealed class ListTasksRequest
{
    public Guid ProjectId { get; set; }
    public List<string>? Status { get; set; }
    public List<string>? Priority { get; set; }
    public Guid? AssigneeId { get; set; }
    public DateOnly? DueBefore { get; set; }
    public DateOnly? DueAfter { get; set; }
    public string? Q { get; set; }
    public string? Sort { get; set; }
    public int? Limit { get; set; }
    public string? Cursor { get; set; }
}

// GET /v1/projects/{projectId}/tasks: filters, three sort orders and keyset paging.
public sealed class ListTasksEndpoint(TasksDbContext db, TeamAccess access) : Endpoint<ListTasksRequest, Paged<TaskDto>>
{
    public override void Configure()
    {
        Get("/v1/projects/{projectId}/tasks");
        Policies(AccessPolicies.Read);
    }

    public override async Task HandleAsync(ListTasksRequest req, CancellationToken ct)
    {
        var limit = Paging.CheckLimit(req.Limit);
        var sort = Paging.CheckSort(req.Sort, "dueDate");
        var statuses = req.Status ?? [];
        var priorities = req.Priority ?? [];
        if (statuses.Any(s => !TaskRules.Statuses.Contains(s)) || priorities.Any(p => !TaskRules.Priorities.Contains(p)))
        {
            throw ProblemException.BadRequest("status or priority is not one of the allowed values.");
        }
        await access.RequireProjectAsync(req.ProjectId, TeamLevel.Member, ct);

        var query = db.Tasks.AsNoTracking().Where(t => t.ProjectId == req.ProjectId);
        if (statuses.Count > 0)
        {
            query = query.Where(t => statuses.Contains(t.Status));
        }
        if (priorities.Count > 0)
        {
            query = query.Where(t => priorities.Contains(t.Priority));
        }
        if (req.AssigneeId is { } assignee)
        {
            query = query.Where(t => t.AssigneeId == assignee);
        }
        if (req.DueBefore is { } before)
        {
            query = query.Where(t => t.DueDate <= before);
        }
        if (req.DueAfter is { } after)
        {
            query = query.Where(t => t.DueDate >= after);
        }
        if (!string.IsNullOrWhiteSpace(req.Q))
        {
            var pattern = Like.Contains(req.Q.Trim());
            query = query.Where(t => EF.Functions.ILike(t.Title, pattern, Like.EscapeChar));
        }

        var page = sort == "dueDate"
            ? await Paging.ToPageAsync(AfterDueCursor(query, req.Cursor)
                    .OrderBy(t => t.DueDate == null).ThenBy(t => t.DueDate).ThenBy(t => t.Id)
                    .Select(Projections.ToTask), limit,
                t => Paging.Encode(t.DueDate?.ToString("O"), t.Id.ToString()), ct)
            : await Paging.ToPageAsync(query.AfterCreatedCursor(req.Cursor, sort == "-createdAt")
                    .OrderByCreated(sort == "-createdAt")
                    .Select(Projections.ToTask), limit,
                t => Paging.CreatedCursor(t.CreatedAt, t.Id), ct);
        await Send.OkAsync(page, ct);
    }

    // Order is due date ascending with undated tasks last, so "after" the last undated task means only undated tasks.
    private static IQueryable<TaskItem> AfterDueCursor(IQueryable<TaskItem> query, string? cursor)
    {
        if (cursor is null)
        {
            return query;
        }
        var data = Paging.Decode(cursor);
        var id = Paging.ParseId(data.Id);
        if (data.Value is null)
        {
            return query.Where(t => t.DueDate == null && t.Id.CompareTo(id) > 0);
        }
        if (!DateOnly.TryParseExact(data.Value, "O", out var due))
        {
            throw ProblemException.BadRequest("The cursor is not valid.");
        }
        return query.Where(t => t.DueDate == null || t.DueDate > due || (t.DueDate == due && t.Id.CompareTo(id) > 0));
    }
}
