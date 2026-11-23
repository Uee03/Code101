#include <iomanip>
#include <iostream>

int main() {
    const int slices_per_pizza{8};
    const int pizzas{3};
    const double price_per_pizza{9.5};

    // TODO: replace 0 with the total number of slices (pizzas times slices per pizza).
    const int total_slices{0};
    // TODO: replace 0.0 with the total cost (pizzas times the price of one pizza).
    const double cost{0.0};

    std::cout << "Pizzas: " << pizzas << '\n';
    std::cout << "Slices: " << total_slices << '\n';
    std::cout << std::fixed << std::setprecision(2);
    std::cout << "Cost: " << cost << '\n';
    return 0;
}
