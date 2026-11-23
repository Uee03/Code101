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
    var newText = LabelV2(first, last, new Address(street, city, zip), express);
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

static string LabelV2(string first, string last, Address address, bool express)
{
    var text = $"{first} {last}\n{address.Street}\n{address.Zip} {address.City}";
    if (express)
    {
        text += "\nEXPRESS";
    }
    return text;
}

record Address(string Street, string City, string Zip);
