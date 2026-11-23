Result<int> ok = Result<int>.Ok(20);
Result<int> failed = Result<int>.Fail(new Error(ErrorKind.NotFound, "number.missing", "No number."));

Result<string> a = ok.Map(n => $"Value is {n * 2}");
Result<string> b = failed.Map(n => $"Value is {n * 2}");

Console.WriteLine(a.Match(v => v, e => e.Code));
Console.WriteLine(b.Match(v => v, e => e.Code));
