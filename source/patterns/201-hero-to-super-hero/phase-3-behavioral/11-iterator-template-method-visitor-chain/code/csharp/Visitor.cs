namespace VisitorDemo;

public interface IShapeVisitor<T>
{
    T VisitSquare(Square square);

    T VisitRect(Rect rect);
}

public abstract class Shape
{
    public abstract T Accept<T>(IShapeVisitor<T> visitor);
}

public class Square : Shape
{
    public Square(int side)
    {
        Side = side;
    }

    public int Side { get; }

    public override T Accept<T>(IShapeVisitor<T> visitor) => visitor.VisitSquare(this);
}

public class Rect : Shape
{
    public Rect(int width, int height)
    {
        Width = width;
        Height = height;
    }

    public int Width { get; }

    public int Height { get; }

    public override T Accept<T>(IShapeVisitor<T> visitor) => visitor.VisitRect(this);
}

public class AreaVisitor : IShapeVisitor<int>
{
    public int VisitSquare(Square square) => square.Side * square.Side;

    public int VisitRect(Rect rect) => rect.Width * rect.Height;
}

public class DescribeVisitor : IShapeVisitor<string>
{
    public string VisitSquare(Square square) => $"square {square.Side}";

    public string VisitRect(Rect rect) => $"rect {rect.Width}x{rect.Height}";
}

public static class Demo
{
    public static void Run()
    {
        var shapes = new Shape[] { new Square(3), new Rect(2, 5) };
        var area = new AreaVisitor();
        var describe = new DescribeVisitor();
        int total = 0;
        foreach (var shape in shapes)
        {
            int value = shape.Accept(area);
            total += value;
            Console.WriteLine($"{shape.Accept(describe)} -> area {value}");
        }
        Console.WriteLine($"total area: {total}");
    }
}
