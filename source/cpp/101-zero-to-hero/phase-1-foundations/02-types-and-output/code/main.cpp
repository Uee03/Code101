#include <iomanip>
#include <iostream>
#include <string>

int main() {
    const std::string item{"Sourdough loaf"};
    int quantity{12};
    const double price{4.5};
    const bool in_stock{true};
    const char grade{'A'};

    quantity = quantity - 2;
    const double total{quantity * price};

    std::cout << "Item: " << item << '\n';
    std::cout << "Quantity: " << quantity << '\n';
    std::cout << "Price: " << price << '\n';
    std::cout << "In stock: " << in_stock << '\n';
    std::cout << std::boolalpha << "In stock (words): " << in_stock << '\n';
    std::cout << "Grade: " << grade << '\n';
    std::cout << std::fixed << std::setprecision(2);
    std::cout << "Total value: " << total << '\n';
    return 0;
}
