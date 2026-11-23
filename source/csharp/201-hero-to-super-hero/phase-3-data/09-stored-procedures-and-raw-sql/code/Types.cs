using Microsoft.EntityFrameworkCore;

public class NoteRow
{
    public int Id { get; set; }

    public string Title { get; set; } = "";

    public bool Archived { get; set; }
}

public class RawContext(string connectionString) : DbContext
{
    protected override void OnConfiguring(DbContextOptionsBuilder options) =>
        options.UseNpgsql(connectionString);
}
