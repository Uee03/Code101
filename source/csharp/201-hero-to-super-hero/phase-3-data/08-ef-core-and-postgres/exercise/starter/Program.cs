using Microsoft.EntityFrameworkCore;

await using (var setup = new NotesContext())
{
    await setup.Database.MigrateAsync();
    await setup.Notebooks.ExecuteDeleteAsync();
    await setup.Tags.ExecuteDeleteAsync();

    var urgent = new Tag { Name = "urgent" };
    var writing = new Tag { Name = "writing" };
    var errands = new Tag { Name = "errands" };

    // TODO: give "Write report" Priority = 2 and "Email Ada" Priority = 1.
    setup.Notebooks.AddRange(
        new Notebook
        {
            Name = "Work",
            Notes =
            [
                new Note { Title = "Write report", Tags = [urgent, writing] },
                new Note { Title = "Email Ada", Tags = [urgent] },
                new Note { Title = "Plan sprint" },
            ],
        },
        new Notebook
        {
            Name = "Home",
            Notes = [new Note { Title = "Buy milk", Tags = [errands] }],
        });

    await setup.SaveChangesAsync();
    Console.WriteLine($"Seeded: {await setup.Notebooks.CountAsync()} notebooks, {await setup.Notes.CountAsync()} notes, {await setup.Tags.CountAsync()} tags");
}

await using (var db = new NotesContext())
{
    var notebooks = await db.Notebooks
        .AsNoTracking()
        .OrderBy(b => b.Name)
        .Select(b => new { b.Name, Titles = b.Notes.OrderBy(n => n.Title).Select(n => n.Title).ToList() })
        .ToListAsync();

    foreach (var notebook in notebooks)
    {
        Console.WriteLine($"{notebook.Name}: {string.Join(", ", notebook.Titles)}");
    }

    var urgentTitles = await db.Tags
        .Where(t => t.Name == "urgent")
        .SelectMany(t => t.Notes)
        .OrderBy(n => n.Title)
        .Select(n => n.Title)
        .ToListAsync();
    Console.WriteLine($"Tag urgent: {string.Join(", ", urgentTitles)}");
}

await using (var untracked = new NotesContext())
{
    await untracked.Notes.AsNoTracking().ToListAsync();
    Console.WriteLine($"No-tracking entries: {untracked.ChangeTracker.Entries().Count()}");
}

await using (var tracked = new NotesContext())
{
    List<Note> notes = await tracked.Notes.OrderBy(n => n.Title).ToListAsync();
    Console.WriteLine($"Tracked entries: {tracked.ChangeTracker.Entries().Count()}");

    notes[0].Done = true;
    Console.WriteLine($"State after edit: {tracked.Entry(notes[0]).State}");

    int saved = await tracked.SaveChangesAsync();
    Console.WriteLine($"Saved changes: {saved}");
}

await using (var bulk = new NotesContext())
{
    int workId = await bulk.Notebooks.Where(b => b.Name == "Work").Select(b => b.Id).SingleAsync();
    int updated = await bulk.Notes
        .Where(n => n.NotebookId == workId)
        .ExecuteUpdateAsync(s => s.SetProperty(n => n.Done, true));
    Console.WriteLine($"Marked done by one UPDATE: {updated}");
}

// TODO: print "Notes with a priority: N", counting notes whose Priority is above 0 (use AsNoTracking and CountAsync).
