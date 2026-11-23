#include <iostream>
#include <map>
#include <string>

int main() {
    std::map<std::string, int> stock{{"apples", 5}, {"plums", 2}};

    // TODO: add 3 more apples to the stock of "apples".
    // TODO: add a new entry "pears" with a stock of 7.

    for (const auto& [name, amount] : stock) {
        std::cout << name << ": " << amount << '\n';
    }
    return 0;
}
