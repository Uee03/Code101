using System.Text.RegularExpressions;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Storage;

namespace TasksApi.Data;

public sealed partial class TasksDbContext(DbContextOptions<TasksDbContext> options) : DbContext(options)
{
    public DbSet<User> Users => Set<User>();
    public DbSet<Team> Teams => Set<Team>();
    public DbSet<TeamMember> TeamMembers => Set<TeamMember>();
    public DbSet<Project> Projects => Set<Project>();
    public DbSet<TaskItem> Tasks => Set<TaskItem>();
    public DbSet<Comment> Comments => Set<Comment>();
    public DbSet<AuditEntry> AuditLog => Set<AuditEntry>();
    public DbSet<IdempotencyKey> IdempotencyKeys => Set<IdempotencyKey>();

    protected override void OnModelCreating(ModelBuilder model)
    {
        model.Entity<User>().ToTable("users");
        model.Entity<Team>().ToTable("teams");
        model.Entity<TeamMember>().ToTable("team_members").HasKey(m => new { m.TeamId, m.UserId });
        model.Entity<Project>().ToTable("projects");
        model.Entity<TaskItem>().ToTable("tasks");
        model.Entity<Comment>().ToTable("comments");
        model.Entity<AuditEntry>().ToTable("audit_log").Property(a => a.Details).HasColumnType("jsonb");
        model.Entity<IdempotencyKey>().ToTable("idempotency_keys").HasKey(k => new { k.UserId, k.Key });
        model.Entity<IdempotencyKey>().Property(k => k.ResponseBody).HasColumnType("jsonb");

        model.Entity<Comment>().HasOne(c => c.TaskItem).WithMany().HasForeignKey(c => c.TaskId);

        // Columns the database fills in (defaults and triggers). EF Core leaves them out of INSERT and UPDATE and reads the result back.
        // Version is also the concurrency token: UPDATE ... WHERE version = <the version the client saw>.
        foreach (var versioned in new[] { typeof(Team), typeof(Project), typeof(TaskItem) })
        {
            model.Entity(versioned).Property(nameof(Team.Version)).IsConcurrencyToken().ValueGeneratedOnAddOrUpdate();
            model.Entity(versioned).Property(nameof(Team.CreatedAt)).ValueGeneratedOnAdd();
            model.Entity(versioned).Property(nameof(Team.UpdatedAt)).ValueGeneratedOnAddOrUpdate();
        }
        model.Entity<TaskItem>().Property(t => t.CompletedAt).ValueGeneratedOnAddOrUpdate();
        model.Entity<Comment>().Property(c => c.CreatedAt).ValueGeneratedOnAdd();
        model.Entity<TeamMember>().Property(m => m.JoinedAt).ValueGeneratedOnAdd();

        // The tables use snake_case column names.
        foreach (var property in model.Model.GetEntityTypes().SelectMany(e => e.GetProperties()))
        {
            property.SetColumnName(SnakeCase().Replace(property.Name, "$1_$2").ToLowerInvariant());
        }
    }

    [GeneratedRegex("([a-z0-9])([A-Z])")]
    private static partial Regex SnakeCase();

    // Starts a transaction and tells the audit trigger who is acting; the setting lasts until the transaction ends.
    public async Task<IDbContextTransaction> BeginWriteAsync(Guid actorId, CancellationToken ct)
    {
        var transaction = await Database.BeginTransactionAsync(ct);
        await Database.ExecuteSqlAsync($"SELECT set_config('app.current_user_id', {actorId.ToString()}, true)", ct);
        return transaction;
    }
}
