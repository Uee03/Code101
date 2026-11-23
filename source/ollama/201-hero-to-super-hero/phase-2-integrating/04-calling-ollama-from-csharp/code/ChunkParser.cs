using System.Text.Json;

namespace OllamaDemo;

public static class ChunkParser
{
    public static ChatChunk Parse(string line) =>
        JsonSerializer.Deserialize<ChatChunk>(line, Json.Options)
        ?? throw new InvalidDataException("A streamed line was JSON null.");
}
