using System.Text;
using OllamaDemo;

Console.OutputEncoding = Encoding.UTF8;

if (args.Contains("--selftest"))
{
    return SelfTest.Run();
}

var stream = args.Contains("--stream");
var prompt = args.FirstOrDefault(arg => !arg.StartsWith("--"))
    ?? "Explain in two sentences what an HTTP timeout is.";

var handler = new SocketsHttpHandler { UseProxy = false };
using var http = new HttpClient(handler)
{
    BaseAddress = new Uri("http://127.0.0.1:11434"),
    Timeout = Timeout.InfiniteTimeSpan,
};
var api = new OllamaApi(http);
var request = new ChatRequest(
    "llama3.2:1b",
    new[] { new ChatMessage("user", prompt) },
    stream,
    new ChatOptions(Temperature: 0.2, NumPredict: 200));

using var cts = new CancellationTokenSource(TimeSpan.FromSeconds(120));
Console.CancelKeyPress += (_, e) =>
{
    e.Cancel = true;
    cts.Cancel();
};

try
{
    if (stream)
    {
        await foreach (var chunk in api.ChatStreamAsync(request, cts.Token))
        {
            Console.Write(chunk.Message?.Content);
            if (chunk.Done)
            {
                Console.WriteLine();
                Console.WriteLine($"[done_reason={chunk.DoneReason} tokens={chunk.EvalCount}]");
            }
        }
    }
    else
    {
        var reply = await api.ChatAsync(request, cts.Token);
        Console.WriteLine(reply.Message?.Content);
        Console.WriteLine($"[done_reason={reply.DoneReason} tokens={reply.EvalCount}]");
    }
    return 0;
}
catch (HttpRequestException error)
{
    Console.Error.WriteLine($"Request failed: {error.Message}");
    return 1;
}
catch (OperationCanceledException)
{
    Console.Error.WriteLine("Cancelled, or no complete answer within 120 seconds.");
    return 1;
}
