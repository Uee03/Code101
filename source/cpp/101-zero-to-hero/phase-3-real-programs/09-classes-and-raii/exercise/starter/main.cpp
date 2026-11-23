#include <iomanip>
#include <iostream>

class Wallet {
public:
    explicit Wallet(long long cents) : balance_cents_{cents} {}

    bool spend(long long cents) {
        // TODO: return false when cents is zero or less, or more than the balance.
        // Otherwise subtract cents from the balance and return true.
        return false;
    }

    long long balance_cents() const { return balance_cents_; }

private:
    long long balance_cents_;
};

void print_money(long long cents) {
    std::cout << cents / 100 << '.' << std::setw(2) << std::setfill('0') << cents % 100;
}

int main() {
    Wallet wallet{2000};
    const bool first{wallet.spend(500)};
    const bool second{wallet.spend(5000)};
    std::cout << std::boolalpha;
    std::cout << "Spent 5.00: " << first << '\n';
    std::cout << "Spent 50.00: " << second << '\n';
    std::cout << "Left: ";
    print_money(wallet.balance_cents());
    std::cout << '\n';
    return 0;
}
