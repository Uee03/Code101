using System.ComponentModel.DataAnnotations;

public sealed class NotesOptions
{
    public const string SectionName = "Notes";

    [Required]
    [MinLength(3)]
    public string Title { get; set; } = "";

    [Range(1, 100)]
    public int PageSize { get; set; } = 10;
}
