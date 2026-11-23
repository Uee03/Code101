string path = Path.Combine(Directory.GetCurrentDirectory(), "shopping.csv");
File.WriteAllText(path, "item,quantity\nBread,2\nMilk,1\n");
Console.Write(File.ReadAllText(path));
