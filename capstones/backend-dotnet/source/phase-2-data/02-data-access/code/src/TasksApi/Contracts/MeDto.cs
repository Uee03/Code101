namespace TasksApi.Contracts;

public sealed record MeTeamDto(Guid TeamId, string Name, string Role);

public sealed record MeDto(
    Guid Id,
    string Username,
    string Email,
    string DisplayName,
    IReadOnlyList<string> Roles,
    IReadOnlyList<string> Scopes,
    IReadOnlyList<MeTeamDto> Teams);
