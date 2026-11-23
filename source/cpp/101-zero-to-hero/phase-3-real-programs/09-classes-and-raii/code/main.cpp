#include <iomanip>
#include <iostream>
#include <string>

class Account {
public:
    explicit Account(const std::string& owner) : owner_{owner} {}

    bool deposit(long long cents) {
        if (cents <= 0) {
            return false;
        }
        balance_cents_ += cents;
        return true;
    }

    bool withdraw(long long cents) {
        if (cents <= 0 || cents > balance_cents_) {
            return false;
        }
        balance_cents_ -= cents;
        return true;
    }

    long long balance_cents() const { return balance_cents_; }
    const std::string& owner() const { return owner_; }

private:
    std::string owner_;
    long long balance_cents_{0};
};

class ScopeLogger {
public:
    explicit ScopeLogger(const std::string& name) : name_{name} {
        std::cout << "enter " << name_ << '\n';
    }

    ~ScopeLogger() {
        std::cout << "leave " << name_ << '\n';
    }

    ScopeLogger(const ScopeLogger&) = delete;
    ScopeLogger& operator=(const ScopeLogger&) = delete;

private:
    std::string name_;
};

void print_money(long long cents) {
    std::cout << cents / 100 << '.' << std::setw(2) << std::setfill('0') << cents % 100;
}

int main() {
    ScopeLogger outer{"main"};

    Account account{"Ada"};
    account.deposit(5000);
    const bool ok{account.withdraw(1250)};
    std::cout << "Withdraw 12.50 worked: " << std::boolalpha << ok << '\n';
    const bool too_much{account.withdraw(100000)};
    std::cout << "Withdraw 1000.00 worked: " << too_much << '\n';
    std::cout << account.owner() << " has ";
    print_money(account.balance_cents());
    std::cout << '\n';

    {
        ScopeLogger inner{"inner block"};
        std::cout << "working inside the block\n";
    }
    std::cout << "after the block\n";
    return 0;
}
