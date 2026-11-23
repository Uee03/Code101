using Microsoft.EntityFrameworkCore;
using TasksApi.Common;
using TasksApi.Data;

namespace TasksApi.Security;

public enum TeamLevel
{
    Member,
    Lead,
}

// Object-level authorization. A user who cannot see a team gets 404 for everything in it, so ids cannot be probed;
// a member who may see it but not change it gets 403. Admins may do everything.
public sealed class TeamAccess(TasksDbContext db, CurrentUser user)
{
    public async Task RequireTeamAsync(Guid teamId, TeamLevel level, CancellationToken ct, string what = "Team")
    {
        var found = await db.Teams
            .Where(t => t.Id == teamId)
            .Select(t => new { Role = t.Members.Where(m => m.UserId == user.Id).Select(m => m.Role).FirstOrDefault() })
            .SingleOrDefaultAsync(ct);
        if (found is null || (found.Role is null && !user.IsAdmin))
        {
            throw ProblemException.NotFound(what);
        }
        if (level == TeamLevel.Lead && !user.IsAdmin && found.Role != "lead")
        {
            throw ProblemException.Forbidden("Only a team lead or an admin can do this.");
        }
    }

    public async Task<Guid> RequireProjectAsync(Guid projectId, TeamLevel level, CancellationToken ct)
    {
        var teamId = await db.Projects.Where(p => p.Id == projectId).Select(p => (Guid?)p.TeamId).SingleOrDefaultAsync(ct)
                     ?? throw ProblemException.NotFound("Project");
        await RequireTeamAsync(teamId, level, ct, "Project");
        return teamId;
    }

    public async Task<Guid> RequireTaskAsync(Guid taskId, TeamLevel level, CancellationToken ct)
    {
        var teamId = await db.Tasks.Where(t => t.Id == taskId).Select(t => (Guid?)t.Project!.TeamId).SingleOrDefaultAsync(ct)
                     ?? throw ProblemException.NotFound("Task");
        await RequireTeamAsync(teamId, level, ct, "Task");
        return teamId;
    }

    // A task may only be given to someone who belongs to the project's team.
    public async Task EnsureAssigneeAsync(Guid teamId, Guid? assigneeId, CancellationToken ct)
    {
        if (assigneeId is { } id && !await db.TeamMembers.AnyAsync(m => m.TeamId == teamId && m.UserId == id, ct))
        {
            throw ProblemException.Unprocessable("The assignee is not a member of the project's team.");
        }
    }
}
