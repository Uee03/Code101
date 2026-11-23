#include <algorithm>
#include <iostream>
#include <map>
#include <numeric>
#include <string>
#include <vector>

int main() {
    const std::vector<std::string> words{"tea", "cake", "tea", "jam", "tea", "cake"};

    std::map<std::string, int> counts;
    for (const std::string& word : words) {
        ++counts[word];
    }

    std::cout << "Word counts:\n";
    for (const auto& [word, count] : counts) {
        std::cout << word << ": " << count << '\n';
    }

    if (counts.contains("jam")) {
        std::cout << "jam appears " << counts.at("jam") << " time(s)\n";
    }
    if (!counts.contains("scone")) {
        std::cout << "no scones today\n";
    }

    std::vector<int> scores{72, 95, 60, 88};
    std::sort(scores.begin(), scores.end());
    std::cout << "Lowest: " << scores.front() << '\n';
    std::cout << "Highest: " << scores.back() << '\n';

    const int total{std::accumulate(scores.begin(), scores.end(), 0)};
    std::cout << "Total: " << total << '\n';

    const auto found{std::find(scores.begin(), scores.end(), 88)};
    if (found != scores.end()) {
        std::cout << "88 is at position " << (found - scores.begin()) << '\n';
    }
    return 0;
}
