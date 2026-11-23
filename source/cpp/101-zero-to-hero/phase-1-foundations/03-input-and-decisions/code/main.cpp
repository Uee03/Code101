#include <iostream>
#include <string>

int main() {
    std::cout << "Your name: ";
    std::string name;
    std::getline(std::cin, name);

    std::cout << "Your age in years: ";
    int age{};
    if (!(std::cin >> age)) {
        std::cout << "That was not a whole number.\n";
        return 1;
    }

    if (age < 0 || age > 120) {
        std::cout << "Please enter an age from 0 to 120.\n";
        return 1;
    }

    int price{};
    if (age < 5) {
        price = 0;
    } else if (age < 18) {
        price = 6;
    } else if (age >= 65) {
        price = 7;
    } else {
        price = 12;
    }

    std::cout << "Hello, " << name << ". Your ticket costs " << price << ".\n";
    return 0;
}
