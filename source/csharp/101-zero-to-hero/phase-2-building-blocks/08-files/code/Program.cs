using System.Globalization;

CultureInfo.CurrentCulture = CultureInfo.InvariantCulture;
string folder = Path.Combine(Directory.GetCurrentDirectory(), "data");
Directory.CreateDirectory(folder);
string path = Path.Combine(folder, "pantry.csv");
string csv = "item,quantity\nRice,3\nSoap,1\n";
File.WriteAllText(path, csv);
Console.WriteLine("Saved data/pantry.csv");
string contents = File.ReadAllText(path);
Console.WriteLine("Read back:");
Console.Write(contents);
string[] lines = contents.Split('\n', StringSplitOptions.RemoveEmptyEntries);
int total = 0;
for (int index = 1; index < lines.Length; index++)
{
    string[] cells = lines[index].Split(',');
    total = total + int.Parse(cells[1]);
}
Console.WriteLine($"Total units: {total}");
