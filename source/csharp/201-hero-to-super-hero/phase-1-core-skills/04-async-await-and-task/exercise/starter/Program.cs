static async Task<int> SquareAsync(int n)
{
    await Task.Delay(50);
    return n * n;
}

int[] inputs = [1, 2, 3, 4];

// TODO: start all four calls at once, wait for them together and print "Squares: 1, 4, 9, 16".
Console.WriteLine("Squares: TODO");
