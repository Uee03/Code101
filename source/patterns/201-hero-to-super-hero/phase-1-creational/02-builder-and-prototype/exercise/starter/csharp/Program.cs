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
        // TODO 1: add the address to _recipients and return this
        throw new NotImplementedException("TODO 1");
    }

    public EmailBuilder WithSubject(string subject)
    {
        // TODO 2: set _subject and return this
        throw new NotImplementedException("TODO 2");
    }

    public EmailBuilder WithBody(string body)
    {
        // TODO 2: set _body and return this
        throw new NotImplementedException("TODO 2");
    }

    public Email Build()
    {
        // TODO 3: throw new InvalidOperationException("an email needs at least one recipient") when _recipients is empty,
        //         otherwise return new Email(_recipients.ToArray(), _subject, _body)
        throw new NotImplementedException("TODO 3");
    }
}
