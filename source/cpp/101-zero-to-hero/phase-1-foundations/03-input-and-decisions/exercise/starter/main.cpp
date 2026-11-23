#include <iostream>
#include <string>

int main() {
    std::cout << "Enter a score from 0 to 100: ";
    int score{};
    if (!(std::cin >> score)) {
        std::cout << "That was not a whole number.\n";
        return 1;
    }
    if (score < 0 || score > 100) {
        std::cout << "The score must be from 0 to 100.\n";
        return 1;
    }

    std::string grade{"?"};
    // TODO: set grade to "A" for 90 or more, "B" for 75 to 89, "C" for 50 to 74
    // and "Try again" for anything below 50.

    std::cout << "Grade: " << grade << '\n';
    return 0;
}
