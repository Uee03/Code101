#include <cstddef>
#include <iostream>
#include <vector>

int* find_first_even(std::vector<int>& numbers) {
    for (int& n : numbers) {
        if (n % 2 == 0) {
            return &n;
        }
    }
    return nullptr;
}

void print_numbers(const std::vector<int>& numbers) {
    for (std::size_t i{0}; i < numbers.size(); ++i) {
        if (i > 0) {
            std::cout << ", ";
        }
        std::cout << numbers[i];
    }
    std::cout << '\n';
}

int main() {
    int age{30};
    int& alias{age};
    int* pointer{&age};

    alias = 31;
    std::cout << "age after alias = 31: " << age << '\n';
    *pointer = 32;
    std::cout << "age after *pointer = 32: " << age << '\n';

    int other{100};
    pointer = &other;
    std::cout << "pointer now reads: " << *pointer << '\n';
    std::cout << "alias still reads: " << alias << '\n';

    std::vector<int> numbers{7, 9, 4, 11};
    int* even{find_first_even(numbers)};
    if (even != nullptr) {
        *even = 0;
    }
    print_numbers(numbers);

    std::vector<int> odds{1, 3, 5};
    if (find_first_even(odds) == nullptr) {
        std::cout << "no even number in odds\n";
    }
    return 0;
}
