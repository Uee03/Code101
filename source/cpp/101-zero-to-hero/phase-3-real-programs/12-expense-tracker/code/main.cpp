#include <cmath>
#include <exception>
#include <filesystem>
#include <iostream>
#include <sstream>
#include <string>

#include "expense_book.hpp"

namespace {

void print_help() {
    std::cout << "Commands:\n"
              << "  add <amount> <label>   example: add 12.50 lunch\n"
              << "  list                   show every expense\n"
              << "  total                  show the sum\n"
              << "  save                   write expenses.txt now\n"
              << "  help                   show this list\n"
              << "  quit                   save and leave\n";
}

void handle_add(ExpenseBook& book, std::istringstream& args) {
    double amount{};
    if (!(args >> amount) || amount <= 0.0 || amount > 1000000.0) {
        std::cout << "Amount must be a number from 0.01 to 1000000.\n";
        return;
    }
    std::string label;
    std::getline(args >> std::ws, label);
    const long long cents{std::llround(amount * 100.0)};
    book.add(cents, label);
    std::cout << "Added " << format_money(cents) << " for " << label << '\n';
}

void print_list(const ExpenseBook& book) {
    if (book.items().empty()) {
        std::cout << "No expenses yet.\n";
        return;
    }
    int number{1};
    for (const Expense& item : book.items()) {
        std::cout << number << ". " << format_money(item.cents) << "  " << item.label << '\n';
        ++number;
    }
}

}  // namespace

int main() {
    const std::string data_file{"expenses.txt"};
    ExpenseBook book;

    try {
        if (std::filesystem::exists(data_file)) {
            book.load(data_file);
            std::cout << "Loaded " << book.items().size() << " expense(s) from " << data_file << '\n';
        }
    } catch (const std::exception& error) {
        std::cout << "Could not load " << data_file << ": " << error.what() << '\n';
        return 1;
    }

    std::cout << "Expense tracker. Type help for commands.\n";
    std::string line;
    while (true) {
        std::cout << "> ";
        if (!std::getline(std::cin, line)) {
            break;
        }
        std::istringstream args{line};
        std::string command;
        args >> command;

        try {
            if (command.empty()) {
                continue;
            }
            if (command == "add") {
                handle_add(book, args);
            } else if (command == "list") {
                print_list(book);
            } else if (command == "total") {
                std::cout << "Total: " << format_money(book.total_cents()) << '\n';
            } else if (command == "save") {
                book.save(data_file);
                std::cout << "Saved to " << data_file << '\n';
            } else if (command == "help") {
                print_help();
            } else if (command == "quit") {
                break;
            } else {
                std::cout << "Unknown command. Type help.\n";
            }
        } catch (const std::exception& error) {
            std::cout << "Error: " << error.what() << '\n';
        }
    }

    try {
        book.save(data_file);
    } catch (const std::exception& error) {
        std::cout << "Could not save: " << error.what() << '\n';
        return 1;
    }
    std::cout << "Saved " << book.items().size() << " expense(s) to " << data_file << '\n';
    return 0;
}
