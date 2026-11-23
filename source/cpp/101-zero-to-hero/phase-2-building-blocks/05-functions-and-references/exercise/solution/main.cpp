#include <iostream>

void apply_discount(double& price, double percent) {
    price -= price * percent / 100.0;
}

int main() {
    double price{50.0};
    apply_discount(price, 20.0);
    std::cout << "Price after discount: " << price << '\n';
    return 0;
}
