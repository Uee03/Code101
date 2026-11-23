var cases = new[]
{
    ("Ana", "Ruiz", "1 Main St", "Oslo", "0150", false),
    ("Bo", "Li", "9 Park Rd", "Bergen", "5003", true),
    ("Cy", "Ott", "3 Hill Way", "Tromso", "9008", true),
};

var differences = 0;
foreach (var (first, last, street, city, zip, express) in cases)
{
    var oldText = Label(first, last, street, city, zip, express);
    string? newText = null; // TODO 3: call LabelV2 with an Address built from street, city and zip
    if (oldText != newText)
    {
        differences++;
    }
}
Console.WriteLine($"{cases.Length} cases, {differences} differences");

static string Label(string first, string last, string street, string city, string zip, bool express)
{
    var text = $"{first} {last}\n{street}\n{zip} {city}";
    if (express)
    {
        text += "\nEXPRESS";
    }
    return text;
}

// TODO 1: write a record Address(string Street, string City, string Zip).

// TODO 2: write a static method LabelV2(string first, string last, Address address, bool express)
//         that returns exactly what Label returns, reading address.Street, address.City and address.Zip.
