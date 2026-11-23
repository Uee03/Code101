namespace TasksApi.Contracts;

// Requests that carry only an id from the route.
public sealed class TeamIdRequest
{
    public Guid TeamId { get; set; }
}

public sealed class ProjectIdRequest
{
    public Guid ProjectId { get; set; }
}

public sealed class TaskIdRequest
{
    public Guid TaskId { get; set; }
}

public sealed class CommentIdRequest
{
    public Guid CommentId { get; set; }
}

// Route id plus the paging query parameters shared by the list operations.
public sealed class PagedRequest
{
    public Guid TeamId { get; set; }
    public Guid ProjectId { get; set; }
    public Guid TaskId { get; set; }
    public int? Limit { get; set; }
    public string? Cursor { get; set; }
}
