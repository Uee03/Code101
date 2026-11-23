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

    std::string grade{"Try again"};
    if (score >= 90) {
        grade = "A";
    } else if (score >= 75) {
        grade = "B";
    } else if (score >= 50) {
        grade = "C";
    }

    std::cout << "Grade: " << grade << '\n';
    return 0;
}
