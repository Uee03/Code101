var queue = new UniqueQueue<string>();
Console.WriteLine(queue.Enqueue("a"));
Console.WriteLine(queue.Enqueue("b"));
Console.WriteLine(queue.Enqueue("a"));
Console.WriteLine($"Count: {queue.Count}");
Console.WriteLine($"Dequeued: {queue.Dequeue()}");
Console.WriteLine(queue.Enqueue("a"));
Console.WriteLine($"Count: {queue.Count}");
