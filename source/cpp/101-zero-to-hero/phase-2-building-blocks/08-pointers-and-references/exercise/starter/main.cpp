#include <iostream>
#include <vector>

const int* find_cheapest(const std::vector<int>& prices) {
    // TODO: return a pointer to the smallest price, or nullptr when the vector is empty.
    return nullptr;
}

void report(const std::vector<int>& prices) {
    const int* cheapest{find_cheapest(prices)};
    if (cheapest != nullptr) {
        std::cout << "Cheapest: " << *cheapest << '\n';
    } else {
        std::cout << "No prices\n";
    }
}

int main() {
    report({5, 3, 8});
    report({});
    return 0;
}
