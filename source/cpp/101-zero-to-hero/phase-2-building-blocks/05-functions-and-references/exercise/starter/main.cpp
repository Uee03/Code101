#include <iostream>

void apply_discount(double& price, double percent) {
    // TODO: lower price by percent percent. For example 20 percent off 50 gives 40.
}

int main() {
    double price{50.0};
    apply_discount(price, 20.0);
    std::cout << "Price after discount: " << price << '\n';
    return 0;
}
