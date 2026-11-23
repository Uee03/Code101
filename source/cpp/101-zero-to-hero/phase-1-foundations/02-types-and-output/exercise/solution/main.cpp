#include <iomanip>
#include <iostream>

int main() {
    const int slices_per_pizza{8};
    const int pizzas{3};
    const double price_per_pizza{9.5};

    const int total_slices{pizzas * slices_per_pizza};
    const double cost{pizzas * price_per_pizza};

    std::cout << "Pizzas: " << pizzas << '\n';
    std::cout << "Slices: " << total_slices << '\n';
    std::cout << std::fixed << std::setprecision(2);
    std::cout << "Cost: " << cost << '\n';
    return 0;
}
