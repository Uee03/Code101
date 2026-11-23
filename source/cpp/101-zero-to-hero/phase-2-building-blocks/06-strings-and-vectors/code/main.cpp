#include <cstddef>
#include <iostream>
#include <string>
#include <vector>

int main() {
    std::string greeting{"Hello"};
    greeting += ", world";
    std::cout << greeting << " has " << greeting.size() << " characters\n";

    const std::size_t comma{greeting.find(',')};
    if (comma != std::string::npos) {
        std::cout << "First word: " << greeting.substr(0, comma) << '\n';
    }

    std::vector<std::string> items;
    items.push_back("bread");
    items.push_back("milk");
    items.push_back("eggs");

    std::cout << "Items: " << items.size() << '\n';
    for (std::size_t i{0}; i < items.size(); ++i) {
        std::cout << i + 1 << ". " << items[i] << '\n';
    }

    const std::vector<int> prices{3, 2, 4};
    int total{0};
    for (const int price : prices) {
        total += price;
    }
    std::cout << "Total price: " << total << '\n';

    std::cout << "Last item: " << items.back() << '\n';
    items.pop_back();
    std::cout << "After pop_back: " << items.size() << " items\n";
    return 0;
}
