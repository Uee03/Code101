namespace OllamaDemo;

public static class SelfTest
{
    private const string Sample = """
        {"model":"x","message":{"role":"assistant","content":"Hel"},"done":false}
        {"model":"x","message":{"role":"assistant","content":"lo"},"done":false}

        {"model":"x","message":{"role":"assistant","content":""},"done":true,"done_reason":"stop","eval_count":2}
        """;

    public static int Run()
    {
        var chunks = new List<ChatChunk>();
        foreach (var line in Sample.Split('\n'))
        {
            var trimmed = line.Trim();
            if (trimmed.Length > 0)
            {
                chunks.Add(ChunkParser.Parse(trimmed));
            }
        }

        var text = string.Concat(chunks.Select(chunk => chunk.Message?.Content));
        var failures = new List<string>();
        Expect(chunks.Count == 3, $"expected 3 chunks, got {chunks.Count}", failures);
        Expect(text == "Hello", $"expected text Hello, got {text}", failures);
        Expect(chunks[^1].Done && chunks[^1].DoneReason == "stop", "the last chunk should be done with reason stop", failures);
        Expect(chunks[^1].EvalCount == 2, "the last chunk should report eval_count 2", failures);

        foreach (var failure in failures)
        {
            Console.Error.WriteLine($"FAIL: {failure}");
        }
        if (failures.Count == 0)
        {
            Console.WriteLine($"selftest ok: {chunks.Count} chunks, text \"{text}\"");
        }
        return failures.Count == 0 ? 0 : 1;
    }

    private static void Expect(bool condition, string message, List<string> failures)
    {
        if (!condition)
        {
            failures.Add(message);
        }
    }
}
