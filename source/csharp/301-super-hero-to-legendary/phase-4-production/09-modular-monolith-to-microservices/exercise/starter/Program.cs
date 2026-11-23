using RoleCheck;

Console.WriteLine(Audience.Includes("\"billing-service\"", "billing-service"));
Console.WriteLine(Audience.Includes("[\"account\",\"billing-service\"]", "billing-service"));
Console.WriteLine(Audience.Includes("[\"account\"]", "billing-service"));
Console.WriteLine(Audience.Includes("42", "billing-service"));
Console.WriteLine(Audience.Includes("not json", "billing-service"));
