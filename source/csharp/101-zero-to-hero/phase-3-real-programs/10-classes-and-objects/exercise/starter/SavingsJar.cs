public class SavingsJar
{
    private int balance;
    public string Name { get; }
    public int Balance => balance;

    public SavingsJar(string name)
    {
        Name = name;
    }

    public void Deposit(int amount)
    {
        if (amount > 0)
        {
            balance = balance + amount;
        }
    }
}
