using System.Net;

public class NotesApiTests(NotesApiFactory factory) : IClassFixture<NotesApiFactory>
{
    private readonly HttpClient _client = factory.CreateClient();

    [Fact]
    public async Task Health_returns_ok()
    {
        HttpResponseMessage response = await _client.GetAsync("/health", TestContext.Current.CancellationToken);

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
    }

    [Fact]
    public async Task Post_creates_a_note_and_get_returns_it()
    {
        HttpResponseMessage created = await _client.PostAsJsonAsync(
            "/notes",
            new { title = "Integration note", body = "from a test" },
            TestContext.Current.CancellationToken);

        Assert.Equal(HttpStatusCode.Created, created.StatusCode);
        NoteResponse? note = await created.Content.ReadFromJsonAsync<NoteResponse>(TestContext.Current.CancellationToken);
        Assert.NotNull(note);
        Assert.Equal("Integration note", note.Title);

        HttpResponseMessage fetched = await _client.GetAsync($"/notes/{note.Id}", TestContext.Current.CancellationToken);
        Assert.Equal(HttpStatusCode.OK, fetched.StatusCode);
    }

    [Fact]
    public async Task Post_with_an_empty_title_returns_a_400_problem()
    {
        HttpResponseMessage response = await _client.PostAsJsonAsync(
            "/notes",
            new { title = "", body = "x" },
            TestContext.Current.CancellationToken);

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
        string json = await response.Content.ReadAsStringAsync(TestContext.Current.CancellationToken);
        Assert.Contains("Title is required.", json);
    }

    [Fact]
    public async Task Get_unknown_id_returns_404()
    {
        HttpResponseMessage response = await _client.GetAsync("/notes/9999", TestContext.Current.CancellationToken);

        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
    }
}
