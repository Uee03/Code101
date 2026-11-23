#include <cstddef>
#include <iostream>
#include <string>
#include <vector>

int main() {
    std::vector<std::string> names{"Ada", "Grace", "Alan"};

    names.push_back("Linus");

    std::cout << "Names: ";
    for (std::size_t i{0}; i < names.size(); ++i) {
        if (i > 0) {
            std::cout << ", ";
        }
        std::cout << names[i];
    }
    std::cout << '\n';
    std::cout << "Count: " << names.size() << '\n';
    return 0;
}
