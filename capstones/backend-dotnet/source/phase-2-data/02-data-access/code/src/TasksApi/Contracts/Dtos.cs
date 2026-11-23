using System.Text.Json;

namespace TasksApi.Contracts;

public sealed record PageInfo(int Limit, string? NextCursor);

public sealed record Paged<T>(IReadOnlyList<T> Items, PageInfo Page);

public sealed record UserSummaryDto(Guid Id, string Username, string DisplayName);

public sealed record MemberDto(Guid UserId, string Username, string DisplayName, string Role, DateTimeOffset JoinedAt);

public sealed record ProjectDto(
    Guid Id,
    Guid TeamId,
    string Key,
    string Name,
    string Description,
    bool Archived,
    int Version,
    DateTimeOffset CreatedAt,
    DateTimeOffset UpdatedAt);

public sealed record TaskDto(
    Guid Id,
    Guid ProjectId,
    string Title,
    string Description,
    string Status,
    string Priority,
    Guid? AssigneeId,
    DateOnly? DueDate,
    DateTimeOffset? CompletedAt,
    Guid CreatedBy,
    int Version,
    DateTimeOffset CreatedAt,
    DateTimeOffset UpdatedAt);

public sealed record CommentDto(Guid Id, Guid TaskId, UserSummaryDto Author, string Body, DateTimeOffset CreatedAt);

public sealed record AuditEntryDto(
    long Id,
    DateTimeOffset OccurredAt,
    Guid? ActorId,
    string Action,
    string EntityType,
    Guid EntityId,
    JsonElement Details);
