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
        var backup = new Dictionary<string, int>(db.Balances);
        try
        {
            foreach (var (name, value) in _pending)
            {
                if (value < 0)
                {
                    throw new ArgumentException($"negative balance for {name}");
                }
                db.Balances[name] = value;
            }
        }
        catch
        {
            db.Balances = backup;
            throw;
        }
        finally
        {
            _pending.Clear();
        }
    }
}
