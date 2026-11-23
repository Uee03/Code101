using System.Diagnostics;
using System.Text;

namespace OllamaDemo;

public sealed class StreamStats
{
    private readonly Stopwatch _clock = Stopwatch.StartNew();
    private readonly StringBuilder _text = new();

    public int Chunks { get; private set; }

    public TimeSpan? FirstChunkAfter { get; private set; }

    public string Text => _text.ToString();

    public void Add(ChatChunk chunk)
    {
        Chunks++;
        var content = chunk.Message?.Content;
        if (FirstChunkAfter is null && !string.IsNullOrEmpty(content))
        {
            FirstChunkAfter = _clock.Elapsed;
        }
        _text.Append(content);
    }
}
