public sealed record Parcel(int WeightKg, string Zone, bool Express, bool Insured, int DeclaredValue, bool Fragile)
{
    public int Surcharges()
    {
        var insurance = Insured ? DeclaredValue / 50 : 0;
        return insurance + (Fragile ? 250 : 0);
    }
}

public class Carrier(int baseCents, int perKg)
{
    public virtual int Price(int weightKg) => baseCents + weightKg * perKg;
}

public sealed class FreightCarrier(int baseCents, int perKg) : Carrier(baseCents, perKg)
{
    public override int Price(int weightKg) => Math.Max(3000, base.Price(weightKg));
}

public static class Shipping
{
    private static readonly Dictionary<string, Carrier> Carriers = new()
    {
        ["post"] = new Carrier(500, 120),
        ["fast"] = new Carrier(900, 200),
        ["freight"] = new FreightCarrier(2000, 60),
    };

    private static readonly Dictionary<string, int> ZoneFees = new() { ["domestic"] = 0, ["eu"] = 400, ["world"] = 1500 };

    public static int LegacyCost(int weightKg, string carrier, bool express, string zone, bool insured, int declaredValue, bool fragile)
    {
        int cost;
        if (carrier == "post")
        {
            cost = 500 + weightKg * 120;
        }
        else if (carrier == "fast")
        {
            cost = 900 + weightKg * 200;
        }
        else if (carrier == "freight")
        {
            cost = 2000 + weightKg * 60;
            if (cost < 3000)
            {
                cost = 3000;
            }
        }
        else
        {
            throw new ArgumentException("unknown carrier: " + carrier);
        }
        if (zone == "eu")
        {
            cost += 400;
        }
        else if (zone == "world")
        {
            cost += 1500;
        }
        if (express)
        {
            cost = cost * 3 / 2;
        }
        if (insured)
        {
            cost += declaredValue / 50;
        }
        if (fragile)
        {
            cost += 250;
        }
        return cost;
    }

    private static int CarrierPrice(string carrier, int weightKg) => carrier switch
    {
        "post" => 500 + weightKg * 120,
        "fast" => 900 + weightKg * 200,
        "freight" => Math.Max(3000, 2000 + weightKg * 60),
        _ => throw new ArgumentException("unknown carrier: " + carrier),
    };

    private static int ZoneFee(string zone) => zone switch
    {
        "eu" => 400,
        "world" => 1500,
        _ => 0,
    };

    public static int Step1Cost(string carrier, Parcel parcel)
    {
        var cost = CarrierPrice(carrier, parcel.WeightKg) + ZoneFee(parcel.Zone);
        if (parcel.Express)
        {
            cost = cost * 3 / 2;
        }
        if (parcel.Insured)
        {
            cost += parcel.DeclaredValue / 50;
        }
        if (parcel.Fragile)
        {
            cost += 250;
        }
        return cost;
    }

    public static int FinalCost(string carrierName, Parcel parcel)
    {
        if (!Carriers.TryGetValue(carrierName, out var carrier))
        {
            throw new ArgumentException("unknown carrier: " + carrierName);
        }
        var cost = carrier.Price(parcel.WeightKg) + ZoneFees.GetValueOrDefault(parcel.Zone, 0);
        if (parcel.Express)
        {
            cost = cost * 3 / 2;
        }
        return cost + parcel.Surcharges();
    }

    public static int BrokenCost(string carrierName, Parcel parcel)
    {
        var carrier = Carriers[carrierName];
        var cost = carrier.Price(parcel.WeightKg) + ZoneFees.GetValueOrDefault(parcel.Zone, 0) + parcel.Surcharges();
        if (parcel.Express)
        {
            cost = cost * 3 / 2;
        }
        return cost;
    }
}
