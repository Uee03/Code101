var shippings = new List<PostShipping>
{
    new PostShipping(),
    new ExpressPostShipping(),
};
foreach (var shipping in shippings)
{
    Console.WriteLine(shipping.CostCents());
}
Console.WriteLine(new CourierShipping().CostCents());
Console.WriteLine(new ExpressCourierShipping().CostCents());

// TODO 1: make an interface ICarrier with BaseCents(), and PostCarrier (300) and CourierCarrier (800).
// TODO 2: make an interface ISpeed with SurchargeCents(), and StandardSpeed (0) and ExpressSpeed (500).
// TODO 3: make one class Shipping(ICarrier carrier, ISpeed speed) whose CostCents() adds the carrier base and the speed surcharge.
// TODO 4: delete the four classes below and the code above. Write two nested foreach loops over the carriers
//         {PostCarrier, CourierCarrier} and the speeds {StandardSpeed, ExpressSpeed}, printing
//         new Shipping(carrier, speed).CostCents(). The output must not change.

class PostShipping
{
    public virtual int CostCents()
    {
        return 300;
    }
}

class ExpressPostShipping : PostShipping
{
    public override int CostCents()
    {
        return base.CostCents() + 500;
    }
}

class CourierShipping
{
    public virtual int CostCents()
    {
        return 800;
    }
}

class ExpressCourierShipping : CourierShipping
{
    public override int CostCents()
    {
        return base.CostCents() + 500;
    }
}
