using Microsoft.Extensions.Options;

public class NoteServiceTests
{
    private static NoteService CreateService() =>
        new(new FakeNoteRepository(), Options.Create(new NotesOptions { PageSize = 2 }));

    [Fact]
    public async Task Create_returns_the_note_with_an_id()
    {
        NoteService service = CreateService();

        Result<Note> result = await service.CreateAsync("Buy milk", "2 litres", TestContext.Current.CancellationToken);

        Assert.True(result.IsSuccess);
        Assert.NotNull(result.Value);
        Assert.Equal(1, result.Value.Id);
        Assert.Equal("Buy milk", result.Value.Title);
    }

    [Fact]
    public async Task Create_rejects_a_duplicate_title_ignoring_case()
    {
        NoteService service = CreateService();
        await service.CreateAsync("Buy milk", "", TestContext.Current.CancellationToken);

        Result<Note> second = await service.CreateAsync("BUY MILK", "", TestContext.Current.CancellationToken);

        Assert.False(second.IsSuccess);
        Assert.Equal("note.duplicate_title", second.Error?.Code);
    }

    [Fact]
    public async Task Get_returns_not_found_for_an_unknown_id()
    {
        NoteService service = CreateService();

        Result<Note> result = await service.GetAsync(99, TestContext.Current.CancellationToken);

        Assert.Equal(ErrorKind.NotFound, result.Error?.Kind);
    }

    [Fact]
    public async Task List_returns_one_page_at_a_time()
    {
        NoteService service = CreateService();
        foreach (string title in new[] { "a", "b", "c" })
        {
            await service.CreateAsync(title, "", TestContext.Current.CancellationToken);
        }

        IReadOnlyList<Note> page2 = await service.ListAsync(2, TestContext.Current.CancellationToken);

        Assert.Equal(new[] { "c" }, page2.Select(n => n.Title));
    }

    [Fact]
    public async Task Create_trims_whitespace_around_the_title()
    {
        NoteService service = CreateService();

        Result<Note> result = await service.CreateAsync("  Buy milk  ", "", TestContext.Current.CancellationToken);

        Assert.True(result.IsSuccess);
        Assert.Equal("Buy milk", result.Value?.Title);
    }

    [Fact]
    public async Task Create_rejects_a_duplicate_that_differs_only_by_spaces()
    {
        NoteService service = CreateService();
        await service.CreateAsync("Buy milk", "", TestContext.Current.CancellationToken);

        Result<Note> second = await service.CreateAsync(" buy milk ", "", TestContext.Current.CancellationToken);

        Assert.Equal("note.duplicate_title", second.Error?.Code);
    }
}
