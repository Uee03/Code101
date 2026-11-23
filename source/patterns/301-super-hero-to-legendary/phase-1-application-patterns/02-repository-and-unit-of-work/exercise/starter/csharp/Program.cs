var db = new Database();
var uow = new UnitOfWork(db);
uow.SetBalance("a", 5);
uow.SetBalance("b", 5);
uow.Commit();
Console.WriteLine($"committed: a={db.Balances["a"]}, b={db.Balances["b"]}");

var bad = new UnitOfWork(db);
bad.SetBalance("a", 1);
bad.SetBalance("b", -1);
try
{
    bad.Commit();
}
catch (ArgumentException error)
{
    Console.WriteLine($"rolled back: {error.Message}");
}
Console.WriteLine($"unchanged: a={db.Balances["a"]}, b={db.Balances["b"]}");

class Database
{
    public Dictionary<string, int> Balances { get; set; } = new() { ["a"] = 10, ["b"] = 0 };
}

class UnitOfWork(Database db)
{
    private readonly SortedDictionary<string, int> _pending = new();

    public void SetBalance(string name, int value) => _pending[name] = value;

    public void Commit()
    {
        // TODO 1: copy the current balances first (the backup).
        // TODO 2: apply every pending value in name order; before assigning a value,
        //         throw new ArgumentException($"negative balance for {name}") if it is below zero.
        // TODO 3: if an error happens, put the backup back (rollback) and throw again.
        // TODO 4: always clear _pending at the end.
        throw new NotImplementedException();
    }
}
