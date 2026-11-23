using System.Linq.Expressions;
using TasksApi.Contracts;

namespace TasksApi.Data;

// Entity to DTO mappings written as expression trees, so EF Core turns them into a SELECT of just those columns.
public static class Projections
{
    public static readonly Expression<Func<Team, TeamDto>> ToTeam = t =>
        new TeamDto(t.Id, t.Name, t.Description, t.Members.Count, t.CreatedBy, t.Version, t.CreatedAt, t.UpdatedAt);

    public static readonly Expression<Func<TeamMember, MemberDto>> ToMember = m =>
        new MemberDto(m.UserId, m.User!.Username, m.User.DisplayName, m.Role, m.JoinedAt);

    public static readonly Expression<Func<Project, ProjectDto>> ToProject = p =>
        new ProjectDto(p.Id, p.TeamId, p.Key, p.Name, p.Description, p.Archived, p.Version, p.CreatedAt, p.UpdatedAt);

    public static readonly Expression<Func<TaskItem, TaskDto>> ToTask = t =>
        new TaskDto(t.Id, t.ProjectId, t.Title, t.Description, t.Status, t.Priority, t.AssigneeId, t.DueDate,
            t.CompletedAt, t.CreatedBy, t.Version, t.CreatedAt, t.UpdatedAt);

    public static readonly Expression<Func<Comment, CommentDto>> ToComment = c =>
        new CommentDto(c.Id, c.TaskId, new UserSummaryDto(c.Author!.Id, c.Author.Username, c.Author.DisplayName), c.Body,
            c.CreatedAt);

    public static readonly Expression<Func<User, UserSummaryDto>> ToUser = u =>
        new UserSummaryDto(u.Id, u.Username, u.DisplayName);
}
