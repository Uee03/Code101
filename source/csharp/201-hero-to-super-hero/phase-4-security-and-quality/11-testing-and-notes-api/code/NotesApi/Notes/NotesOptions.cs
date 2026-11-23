using System.ComponentModel.DataAnnotations;

public sealed class NotesOptions
{
    public const string SectionName = "Notes";

    [Range(1, 100)]
    public int PageSize { get; set; } = 10;
}
