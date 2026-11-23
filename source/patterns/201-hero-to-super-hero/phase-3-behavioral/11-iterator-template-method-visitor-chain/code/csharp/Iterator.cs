using System.Collections;

namespace IteratorDemo;

public class Playlist : IEnumerable<string>
{
    private readonly List<string> _songs;

    public Playlist(List<string> songs)
    {
        _songs = songs;
    }

    public IEnumerator<string> GetEnumerator() => _songs.GetEnumerator();

    IEnumerator IEnumerable.GetEnumerator() => GetEnumerator();

    public IEnumerable<string> Backwards()
    {
        for (int i = _songs.Count - 1; i >= 0; i--)
        {
            yield return _songs[i];
        }
    }
}

public static class Demo
{
    public static void Run()
    {
        var playlist = new Playlist(new List<string> { "Intro", "Verse", "Chorus" });
        Console.WriteLine($"forward: {string.Join(", ", playlist)}");
        Console.WriteLine($"backwards: {string.Join(", ", playlist.Backwards())}");
        using var first = playlist.GetEnumerator();
        using var second = playlist.GetEnumerator();
        first.MoveNext();
        string a = first.Current;
        first.MoveNext();
        string b = first.Current;
        second.MoveNext();
        Console.WriteLine($"first: {a}, {b}");
        Console.WriteLine($"second: {second.Current}");
    }
}
