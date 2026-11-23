using System.Globalization;

CultureInfo.CurrentCulture = CultureInfo.InvariantCulture;

var notes = new InMemoryRepository<Note>();
notes.Add(new Note(1, "Buy milk"));
notes.Add(new Note(2, "Call Ada tomorrow"));

Console.WriteLine(notes.Find(2)?.Title ?? "missing");
Console.WriteLine(notes.Find(9)?.Title ?? "missing");

try
{
    notes.Add(new Note(1, "Duplicate"));
}
catch (InvalidOperationException ex)
{
    Console.WriteLine(ex.Message);
}

Note longest = Pick.LargestBy(notes.All(), n => n.Title.Length);
Console.WriteLine($"Longest title: {longest.Title}");

IEnumerable<IEntity> asEntities = notes.All();
int idSum = 0;
foreach (IEntity entity in asEntities)
{
    idSum += entity.Id;
}

Console.WriteLine($"Sum of ids: {idSum}");

var counts = new SortedDictionary<string, int>(StringComparer.OrdinalIgnoreCase);
foreach (string word in "the cat saw the Cat".Split(' '))
{
    counts[word] = counts.GetValueOrDefault(word) + 1;
}

foreach (var (word, count) in counts)
{
    Console.WriteLine($"{word}: {count}");
}

var seen = new HashSet<string>();
var duplicates = new List<string>();
foreach (string item in new[] { "a", "b", "a", "c", "b" })
{
    if (!seen.Add(item))
    {
        duplicates.Add(item);
    }
}

Console.WriteLine($"Duplicates: {string.Join(",", duplicates)}");

var queue = new Queue<string>();
queue.Enqueue("first");
queue.Enqueue("second");
Console.WriteLine($"Dequeued: {queue.Dequeue()}, left: {queue.Count}");
