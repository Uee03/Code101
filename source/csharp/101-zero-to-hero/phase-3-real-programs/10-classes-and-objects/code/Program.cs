Counter first = new Counter("Tickets", 2);
Counter second = new Counter("Drinks", 0);
first.Add(3);
Console.WriteLine($"{first.Name}: {first.Count}");
Console.WriteLine($"{second.Name}: {second.Count}");
