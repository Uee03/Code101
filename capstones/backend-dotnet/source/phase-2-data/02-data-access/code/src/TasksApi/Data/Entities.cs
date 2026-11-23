namespace TasksApi.Data;

// Plain classes that mirror the tables in db/schema.sql. The database owns the schema; EF Core only maps to it.

public interface ICreated
{
    Guid Id { get; }
    DateTimeOffset CreatedAt { get; }
}

public sealed class User
{
    public Guid Id { get; set; }
    public string Username { get; set; } = "";
    public string Email { get; set; } = "";
    public string DisplayName { get; set; } = "";
    public DateTimeOffset CreatedAt { get; set; }
    public DateTimeOffset UpdatedAt { get; set; }
}

public sealed class Team : ICreated
{
    public Guid Id { get; set; }
    public string Name { get; set; } = "";
    public string Description { get; set; } = "";
    public Guid CreatedBy { get; set; }
    public int Version { get; set; }
    public DateTimeOffset CreatedAt { get; set; }
    public DateTimeOffset UpdatedAt { get; set; }
    public List<TeamMember> Members { get; set; } = [];
}

public sealed class TeamMember
{
    public Guid TeamId { get; set; }
    public Guid UserId { get; set; }
    public string Role { get; set; } = "member";
    public DateTimeOffset JoinedAt { get; set; }
    public Team? Team { get; set; }
    public User? User { get; set; }
}

public sealed class Project : ICreated
{
    public Guid Id { get; set; }
    public Guid TeamId { get; set; }
    public string Key { get; set; } = "";
    public string Name { get; set; } = "";
    public string Description { get; set; } = "";
    public bool Archived { get; set; }
    public Guid CreatedBy { get; set; }
    public int Version { get; set; }
    public DateTimeOffset CreatedAt { get; set; }
    public DateTimeOffset UpdatedAt { get; set; }
}

// Named TaskItem so it never clashes with System.Threading.Tasks.Task.
public sealed class TaskItem : ICreated
{
    public Guid Id { get; set; }
    public Guid ProjectId { get; set; }
    public string Title { get; set; } = "";
    public string Description { get; set; } = "";
    public string Status { get; set; } = "todo";
    public string Priority { get; set; } = "medium";
    public Guid? AssigneeId { get; set; }
    public DateOnly? DueDate { get; set; }
    public DateTimeOffset? CompletedAt { get; set; }
    public Guid CreatedBy { get; set; }
    public int Version { get; set; }
    public DateTimeOffset CreatedAt { get; set; }
    public DateTimeOffset UpdatedAt { get; set; }
    public Project? Project { get; set; }
}

public sealed class Comment : ICreated
{
    public Guid Id { get; set; }
    public Guid TaskId { get; set; }
    public Guid AuthorId { get; set; }
    public string Body { get; set; } = "";
    public DateTimeOffset CreatedAt { get; set; }
    public TaskItem? TaskItem { get; set; }
    public User? Author { get; set; }
}

public sealed class AuditEntry
{
    public long Id { get; set; }
    public DateTimeOffset OccurredAt { get; set; }
    public Guid? ActorId { get; set; }
    public string Action { get; set; } = "";
    public string EntityType { get; set; } = "";
    public Guid EntityId { get; set; }
    public string Details { get; set; } = "{}";
}

public sealed class IdempotencyKey
{
    public Guid UserId { get; set; }
    public string Key { get; set; } = "";
    public string RequestHash { get; set; } = "";
    public int? StatusCode { get; set; }
    public string? ResponseBody { get; set; }
    public DateTimeOffset CreatedAt { get; set; }
    public DateTimeOffset ExpiresAt { get; set; }
}
