#include <iostream>
#include <vector>

const int* find_cheapest(const std::vector<int>& prices) {
    if (prices.empty()) {
        return nullptr;
    }
    const int* cheapest{&prices[0]};
    for (const int& price : prices) {
        if (price < *cheapest) {
            cheapest = &price;
        }
    }
    return cheapest;
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
