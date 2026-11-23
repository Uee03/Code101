using Microsoft.EntityFrameworkCore;

public class NotesContext : DbContext
{
    public DbSet<Notebook> Notebooks => Set<Notebook>();

    public DbSet<Note> Notes => Set<Note>();

    public DbSet<Tag> Tags => Set<Tag>();

    protected override void OnConfiguring(DbContextOptionsBuilder options)
    {
        string connection = Environment.GetEnvironmentVariable("NOTES_CONNECTION")
            ?? throw new InvalidOperationException("Set the NOTES_CONNECTION environment variable (see .env.example).");
        options.UseNpgsql(connection);
    }

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<Notebook>(e =>
        {
            e.Property(x => x.Name).HasMaxLength(100);
            e.HasIndex(x => x.Name).IsUnique();
        });

        modelBuilder.Entity<Note>(e =>
        {
            e.Property(x => x.Title).HasMaxLength(200);
            e.HasOne(x => x.Notebook).WithMany(x => x.Notes).HasForeignKey(x => x.NotebookId);
        });

        modelBuilder.Entity<Tag>(e =>
        {
            e.Property(x => x.Name).HasMaxLength(50);
            e.HasIndex(x => x.Name).IsUnique();
        });
    }
}
