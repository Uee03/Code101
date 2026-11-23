#include <cstddef>
#include <iostream>
#include <string>
#include <vector>

int main() {
    std::vector<std::string> names{"Ada", "Grace", "Alan"};

    // TODO: add the name "Linus" to the end of the vector.

    std::cout << "Names: ";
    for (std::size_t i{0}; i < names.size(); ++i) {
        // TODO: print ", " before every name except the first one.
        std::cout << names[i];
    }
    std::cout << '\n';
    std::cout << "Count: " << names.size() << '\n';
    return 0;
}
