public interface IGreeter
{
    string Greet(string name);
}

public sealed class EnglishGreeter : IGreeter
{
    public string Greet(string name) => $"Hello, {name}";
}

public sealed class RequestId
{
}
