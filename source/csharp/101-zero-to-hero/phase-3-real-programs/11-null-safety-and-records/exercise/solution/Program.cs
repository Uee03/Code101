string? email = null;
Contact person = new Contact("Ada", email);
Console.WriteLine($"{person.Name}: {person.Email ?? "(no email)"}");
Contact updated = person with { Email = "ada@example.test" };
Console.WriteLine($"{updated.Name}: {updated.Email}");
