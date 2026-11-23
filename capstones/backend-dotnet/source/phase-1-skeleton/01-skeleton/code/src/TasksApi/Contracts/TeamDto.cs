namespace TasksApi.Contracts;

public sealed record TeamDto(
    Guid Id,
    string Name,
    string Description,
    int MemberCount,
    Guid CreatedBy,
    int Version,
    DateTimeOffset CreatedAt,
    DateTimeOffset UpdatedAt);
