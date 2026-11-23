#include "expense_book.hpp"

#include <fstream>
#include <iomanip>
#include <sstream>
#include <stdexcept>

void ExpenseBook::add(long long cents, const std::string& label) {
    if (cents <= 0) {
        throw std::invalid_argument("amount must be more than zero");
    }
    if (label.empty()) {
        throw std::invalid_argument("label must not be empty");
    }
    items_.push_back(Expense{cents, label});
}

long long ExpenseBook::total_cents() const {
    long long total{0};
    for (const Expense& item : items_) {
        total += item.cents;
    }
    return total;
}

const std::vector<Expense>& ExpenseBook::items() const {
    return items_;
}

void ExpenseBook::save(const std::string& path) const {
    std::ofstream out{path};
    if (!out) {
        throw std::runtime_error("cannot open " + path + " for writing");
    }
    for (const Expense& item : items_) {
        out << item.cents << ' ' << item.label << '\n';
    }
    if (!out) {
        throw std::runtime_error("failed while writing " + path);
    }
}

void ExpenseBook::load(const std::string& path) {
    std::ifstream in{path};
    if (!in) {
        throw std::runtime_error("cannot open " + path + " for reading");
    }
    std::vector<Expense> loaded;
    long long cents{};
    while (in >> cents) {
        std::string label;
        std::getline(in >> std::ws, label);
        if (cents <= 0 || label.empty()) {
            throw std::runtime_error("bad line in " + path);
        }
        loaded.push_back(Expense{cents, label});
    }
    if (!in.eof()) {
        throw std::runtime_error("bad data in " + path);
    }
    items_ = loaded;
}

std::string format_money(long long cents) {
    std::ostringstream text;
    text << cents / 100 << '.' << std::setw(2) << std::setfill('0') << cents % 100;
    return text.str();
}
