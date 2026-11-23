using System.Globalization;

CultureInfo.CurrentCulture = CultureInfo.InvariantCulture;
SelfCheck();
string path = Path.Combine(Directory.GetCurrentDirectory(), "expenses.csv");
List<Expense> expenses = LoadExpenses(path);
Console.WriteLine($"Loaded: {expenses.Count}");
while (true)
{
    Console.WriteLine("1 Add | 2 List | 3 Save | 4 Total | 0 Exit");
    string choice = Console.ReadLine() ?? "0";
    if (choice == "0")
    {
        Console.WriteLine("Bye (only saved changes are kept).");
        break;
    }
    switch (choice)
    {
        case "1":
            AddExpense(expenses);
            break;
        case "2":
            ShowExpenses(expenses);
            break;
        case "3":
            try
            {
                File.WriteAllText(path, ToCsv(expenses));
                Console.WriteLine("Saved expenses.csv");
            }
            catch (IOException)
            {
                Console.WriteLine("Could not save: file is busy or storage failed.");
            }
            catch (UnauthorizedAccessException)
            {
                Console.WriteLine("Could not save: folder is not writable.");
            }
            break;
        // TODO: add case "4" to sum Amount values and print Total with F2.
        default:
            Console.WriteLine("Choose 1, 2, 3, 4 or 0.");
            break;
    }
}

static void AddExpense(List<Expense> expenses)
{
    Console.WriteLine("Description (no commas):");
    string description = (Console.ReadLine() ?? "").Trim();
    if (description == "" || description.Contains(',') || description.Contains('\r') || description.Contains('\n'))
    {
        Console.WriteLine("Use a nonempty description without commas or line breaks.");
        return;
    }
    Console.WriteLine("Amount (positive, dot for decimals):");
    if (!decimal.TryParse(Console.ReadLine(), NumberStyles.AllowDecimalPoint, CultureInfo.InvariantCulture, out decimal amount) || amount <= 0)
    {
        Console.WriteLine("Invalid amount; nothing added.");
        return;
    }
    expenses.Add(new Expense(description, amount));
    Console.WriteLine("Added.");
}

static void ShowExpenses(List<Expense> expenses)
{
    decimal total = 0m;
    foreach (Expense expense in expenses)
    {
        Console.WriteLine($"{expense.Description}: {expense.Amount:F2}");
        total = total + expense.Amount;
    }
    Console.WriteLine($"Total: {total:F2}");
}

static string ToCsv(List<Expense> expenses)
{
    string csv = "description,amount\n";
    foreach (Expense expense in expenses)
    {
        csv = csv + $"{expense.Description},{expense.Amount.ToString(CultureInfo.InvariantCulture)}\n";
    }
    return csv;
}

static List<Expense> LoadExpenses(string path)
{
    List<Expense> expenses = new List<Expense>();
    if (!File.Exists(path))
    {
        return expenses;
    }
    try
    {
        string[] lines = File.ReadAllText(path).Split('\n');
        if (lines.Length == 0 || lines[0].TrimEnd('\r') != "description,amount")
        {
            Console.WriteLine("Unrecognized CSV header; keep a backup before saving.");
            return expenses;
        }
        for (int index = 1; index < lines.Length; index++)
        {
            string line = lines[index].TrimEnd('\r');
            if (string.IsNullOrWhiteSpace(line))
            {
                continue;
            }
            try
            {
                expenses.Add(ParseExpense(line));
            }
            catch (FormatException)
            {
                Console.WriteLine($"Skipped invalid CSV row {index + 1}.");
            }
        }
    }
    catch (IOException)
    {
        Console.WriteLine("Could not load expenses.csv; keep a backup before saving.");
    }
    catch (UnauthorizedAccessException)
    {
        Console.WriteLine("Cannot read expenses.csv; keep a backup before saving.");
    }
    return expenses;
}

static Expense ParseExpense(string line)
{
    string[] cells = line.Split(',');
    if (cells.Length != 2 || cells[0].Trim() == "" || !decimal.TryParse(cells[1], NumberStyles.AllowDecimalPoint, CultureInfo.InvariantCulture, out decimal amount) || amount <= 0)
    {
        throw new FormatException("Invalid expense row.");
    }
    return new Expense(cells[0], amount);
}

static void SelfCheck()
{
    Expense sample = new Expense("Tea", 2.50m);
    string csv = ToCsv(new List<Expense> { sample });
    string row = csv.Split('\n')[1];
    Expense restored = ParseExpense(row);
    Assert(restored == sample, "CSV round trip keeps the expense.");
    Assert(csv.StartsWith("description,amount\n"), "CSV includes the header.");
    Console.WriteLine("Self-check passed.");
}

static void Assert(bool condition, string message)
{
    if (!condition)
    {
        throw new InvalidOperationException(message);
    }
}
