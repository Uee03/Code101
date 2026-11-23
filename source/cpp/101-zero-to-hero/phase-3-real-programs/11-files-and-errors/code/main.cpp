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
    try {
        save_lines("notes.txt", {"buy bread", "call Sam", "read chapter 11"});
        const std::vector<std::string> lines{load_lines("notes.txt")};
        std::cout << "Read " << lines.size() << " lines:\n";
        for (const std::string& line : lines) {
            std::cout << "- " << line << '\n';
        }
    } catch (const std::exception& error) {
        std::cout << "Error: " << error.what() << '\n';
        return 1;
    }

    try {
        load_lines("missing-file.txt");
    } catch (const std::exception& error) {
        std::cout << "Error: " << error.what() << '\n';
    }
    std::cout << "Done\n";
    return 0;
}
