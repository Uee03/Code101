using System.Net.Http.Json;
using System.Runtime.CompilerServices;

namespace OllamaDemo;

public sealed class OllamaApi(HttpClient http)
{
    public async Task<ChatChunk> ChatAsync(ChatRequest request, CancellationToken cancellationToken)
    {
        using var response = await http.PostAsJsonAsync(
            "/api/chat", request with { Stream = false }, Json.Options, cancellationToken);
        response.EnsureSuccessStatusCode();
        var chunk = await response.Content.ReadFromJsonAsync<ChatChunk>(Json.Options, cancellationToken);
        return chunk ?? throw new InvalidDataException("The reply body was empty.");
    }

    public async IAsyncEnumerable<ChatChunk> ChatStreamAsync(
        ChatRequest request, [EnumeratorCancellation] CancellationToken cancellationToken)
    {
        using var message = new HttpRequestMessage(HttpMethod.Post, "/api/chat")
        {
            Content = JsonContent.Create(request with { Stream = true }, options: Json.Options),
        };
        using var response = await http.SendAsync(
            message, HttpCompletionOption.ResponseHeadersRead, cancellationToken);
        response.EnsureSuccessStatusCode();
        await using var stream = await response.Content.ReadAsStreamAsync(cancellationToken);
        using var reader = new StreamReader(stream);
        while (await reader.ReadLineAsync(cancellationToken) is { } line)
        {
            if (line.Length == 0)
            {
                continue;
            }
            yield return ChunkParser.Parse(line);
        }
    }
}
