#include <iostream>
#include <map>
#include <string>

int main() {
    std::map<std::string, int> stock{{"apples", 5}, {"plums", 2}};

    stock["apples"] += 3;
    stock["pears"] = 7;

    for (const auto& [name, amount] : stock) {
        std::cout << name << ": " << amount << '\n';
    }
    return 0;
}
