#include <iostream>
#include <string>

int main() {
    std::cout << "Times table for 3\n";
    for (int i{1}; i <= 5; ++i) {
        std::cout << "3 x " << i << " = " << 3 * i << '\n';
    }

    std::cout << "Countdown\n";
    int count{3};
    while (count > 0) {
        std::cout << count << '\n';
        --count;
    }
    std::cout << "Liftoff!\n";

    std::cout << "Letters in 'cake' that are not 'a':\n";
    const std::string word{"cake"};
    for (const char letter : word) {
        if (letter == 'a') {
            continue;
        }
        std::cout << letter << '\n';
    }

    std::cout << "Enter whole numbers to add up. Enter 0 to stop.\n";
    int total{0};
    while (true) {
        int number{};
        if (!(std::cin >> number)) {
            std::cout << "Not a number, stopping.\n";
            break;
        }
        if (number == 0) {
            break;
        }
        total += number;
    }
    std::cout << "Total: " << total << '\n';
    return 0;
}
