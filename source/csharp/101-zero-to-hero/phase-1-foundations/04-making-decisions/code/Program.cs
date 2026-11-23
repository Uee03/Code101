Console.WriteLine("Age (whole number):");
int age = int.Parse(Console.ReadLine() ?? "");
bool hasTicket = true;
Console.WriteLine($"Adult with ticket: {age >= 18 && hasTicket}");
Console.WriteLine($"Child or has ticket: {age < 18 || hasTicket}");
Console.WriteLine($"No ticket: {!hasTicket}");
Console.WriteLine($"Exactly 18: {age == 18}; not 18: {age != 18}");
Console.WriteLine($"At most 65: {age <= 65}; over 65: {age > 65}");
if (age < 0)
{
    Console.WriteLine("Age cannot be negative.");
}
else if (age < 5)
{
    Console.WriteLine("Ticket: free");
}
else if (age < 18)
{
    Console.WriteLine("Ticket: child price, 5.00");
}
else if (age < 65)
{
    Console.WriteLine("Ticket: adult price, 10.00");
}
else
{
    Console.WriteLine("Ticket: senior price, 7.00");
}
string lane = hasTicket switch
{
    true => "Go to the gate",
    false => "Buy a ticket"
};
Console.WriteLine(lane);
