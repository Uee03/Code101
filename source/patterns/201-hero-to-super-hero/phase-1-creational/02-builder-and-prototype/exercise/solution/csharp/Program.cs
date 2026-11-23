var email = new EmailBuilder()
    .AddRecipient("ana@example.com")
    .AddRecipient("bo@example.com")
    .WithSubject("Hello")
    .WithBody("Hi!")
    .Build();
Console.WriteLine(email.Describe());
try
{
    new EmailBuilder().WithSubject("Lonely").Build();
}
catch (InvalidOperationException error)
{
    Console.WriteLine($"Rejected: {error.Message}");
}

record Email(IReadOnlyList<string> Recipients, string Subject, string Body)
{
    public string Describe() => $"To: {string.Join(", ", Recipients)} | Subject: {Subject} | Body: {Body}";
}

class EmailBuilder
{
    private readonly List<string> _recipients = new();
    private string _subject = "(no subject)";
    private string _body = "";

    public EmailBuilder AddRecipient(string address)
    {
        _recipients.Add(address);
        return this;
    }

    public EmailBuilder WithSubject(string subject)
    {
        _subject = subject;
        return this;
    }

    public EmailBuilder WithBody(string body)
    {
        _body = body;
        return this;
    }

    public Email Build()
    {
        if (_recipients.Count == 0)
        {
            throw new InvalidOperationException("an email needs at least one recipient");
        }
        return new Email(_recipients.ToArray(), _subject, _body);
    }
}
