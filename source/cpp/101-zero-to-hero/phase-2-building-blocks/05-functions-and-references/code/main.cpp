#include <iostream>
#include <string>

struct Dimensions {
    int area;
    int perimeter;
};

Dimensions measure(int width, int height) {
    return Dimensions{width * height, 2 * (width + height)};
}

void add_tip(double& bill, double percent) {
    bill += bill * percent / 100.0;
}

void print_greeting(const std::string& name) {
    std::cout << "Hello, " << name << "!\n";
}

int main() {
    const Dimensions room{measure(3, 4)};
    std::cout << "Area: " << room.area << " Perimeter: " << room.perimeter << '\n';

    double bill{80.0};
    add_tip(bill, 10.0);
    std::cout << "Bill with tip: " << bill << '\n';

    print_greeting("Ada");
    return 0;
}
