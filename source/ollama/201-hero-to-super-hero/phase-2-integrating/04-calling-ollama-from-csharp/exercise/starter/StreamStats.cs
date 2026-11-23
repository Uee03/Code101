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
        // TODO 1: count the chunk
        // TODO 2: the first time a chunk carries non-empty content, remember _clock.Elapsed in FirstChunkAfter
        // TODO 3: append the chunk's content (when there is any) to _text
    }
}
