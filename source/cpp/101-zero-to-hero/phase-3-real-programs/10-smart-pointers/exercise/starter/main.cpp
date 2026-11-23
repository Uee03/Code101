#include <iostream>
#include <memory>

class Ticket {
public:
    explicit Ticket(int number) : number_{number} {
        std::cout << "issue " << number_ << '\n';
    }

    ~Ticket() {
        std::cout << "void " << number_ << '\n';
    }

    Ticket(const Ticket&) = delete;
    Ticket& operator=(const Ticket&) = delete;

    int number() const { return number_; }

private:
    int number_;
};

std::unique_ptr<Ticket> make_ticket(int number) {
    // TODO: create a Ticket with this number and return the unique_ptr that owns it.
    return nullptr;
}

int main() {
    const std::unique_ptr<Ticket> ticket{make_ticket(7)};
    if (ticket == nullptr) {
        std::cout << "no ticket\n";
        return 0;
    }
    std::cout << "using ticket " << ticket->number() << '\n';
    return 0;
}
