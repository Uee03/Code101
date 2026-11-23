#include <cstddef>
#include <exception>
#include <fstream>
#include <iostream>
#include <stdexcept>
#include <string>
#include <vector>

void save_lines(const std::string& path, const std::vector<std::string>& lines) {
    std::ofstream out{path};
    if (!out) {
        throw std::runtime_error("cannot open " + path + " for writing");
    }
    for (const std::string& line : lines) {
        out << line << '\n';
    }
}

std::vector<std::string> load_lines(const std::string& path) {
    std::ifstream in{path};
    if (!in) {
        throw std::runtime_error("cannot open " + path + " for reading");
    }
    std::vector<std::string> lines;
    std::string line;
    while (std::getline(in, line)) {
        lines.push_back(line);
    }
    return lines;
}

int main() {
    save_lines("todo.txt", {"wash car", "pay rent"});
    const std::vector<std::string> todo{load_lines("todo.txt")};
    for (std::size_t i{0}; i < todo.size(); ++i) {
        std::cout << i + 1 << ". " << todo[i] << '\n';
    }

    // TODO: call load_lines("archive.txt"). That file does not exist, so it throws.
    // Catch the error and print "Could not read: " followed by the error text, then carry on.

    std::cout << "Done\n";
    return 0;
}
