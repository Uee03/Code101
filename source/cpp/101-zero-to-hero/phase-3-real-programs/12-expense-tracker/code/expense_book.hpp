#pragma once

#include <string>
#include <vector>

struct Expense {
    long long cents;
    std::string label;
};

class ExpenseBook {
public:
    void add(long long cents, const std::string& label);
    long long total_cents() const;
    const std::vector<Expense>& items() const;
    void save(const std::string& path) const;
    void load(const std::string& path);

private:
    std::vector<Expense> items_;
};

std::string format_money(long long cents);
