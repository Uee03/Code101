public class Notebook
{
    public int Id { get; set; }

    public string Name { get; set; } = "";

    public List<Note> Notes { get; set; } = [];
}

public class Note
{
    public int Id { get; set; }

    public string Title { get; set; } = "";

    public bool Done { get; set; }

    // TODO: add an int property named Priority (the default value 0 is fine).

    public int NotebookId { get; set; }

    public Notebook Notebook { get; set; } = null!;

    public List<Tag> Tags { get; set; } = [];
}

public class Tag
{
    public int Id { get; set; }

    public string Name { get; set; } = "";

    public List<Note> Notes { get; set; } = [];
}
