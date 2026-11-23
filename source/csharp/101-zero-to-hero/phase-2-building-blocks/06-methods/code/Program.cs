using System.Globalization;

CultureInfo.CurrentCulture = CultureInfo.InvariantCulture;
double roomArea = Area(3, 4);
double paintLitres = roomArea / 6;
PrintEstimate("Kitchen", paintLitres);

static double Area(double width, double height)
{
    double result = width * height;
    return result;
}

static void PrintEstimate(string room, double litres)
{
    Console.WriteLine($"{room}: {litres:F2} litres");
}
