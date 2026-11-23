public record Order(int Id, string Customer, string Category, decimal Total, DateOnly Date);

public record Customer(string Name, string City);
