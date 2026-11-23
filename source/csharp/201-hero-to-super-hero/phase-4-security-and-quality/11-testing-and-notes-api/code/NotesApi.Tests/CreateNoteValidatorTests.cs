public class CreateNoteValidatorTests
{
    private readonly CreateNoteValidator _validator = new();

    [Theory]
    [InlineData(null)]
    [InlineData("")]
    public void Title_is_required(string? title)
    {
        var result = _validator.Validate(new CreateNoteRequest(title, "body"));

        Assert.Contains(result.Errors, e => e.PropertyName == "Title" && e.ErrorMessage == "Title is required.");
    }

    [Fact]
    public void A_title_of_101_characters_is_too_long()
    {
        var result = _validator.Validate(new CreateNoteRequest(new string('x', 101), null));

        Assert.False(result.IsValid);
    }

    [Fact]
    public void A_normal_request_is_valid()
    {
        var result = _validator.Validate(new CreateNoteRequest("Buy milk", "2 litres"));

        Assert.True(result.IsValid);
    }
}
