#include <iostream>
#include <memory>
#include <string>
#include <utility>

class Document {
public:
    explicit Document(const std::string& title) : title_{title} {
        std::cout << "open " << title_ << '\n';
    }

    ~Document() {
        std::cout << "close " << title_ << '\n';
    }

    Document(const Document&) = delete;
    Document& operator=(const Document&) = delete;

    const std::string& title() const { return title_; }

private:
    std::string title_;
};

std::unique_ptr<Document> make_document(const std::string& title) {
    return std::make_unique<Document>(title);
}

void print_title(const Document& doc) {
    std::cout << "title: " << doc.title() << '\n';
}

void take_and_finish(std::unique_ptr<Document> doc) {
    std::cout << "finishing " << doc->title() << '\n';
}

int main() {
    std::unique_ptr<Document> report{make_document("report")};
    print_title(*report);

    take_and_finish(std::move(report));
    if (report == nullptr) {
        std::cout << "report was handed over\n";
    }

    {
        const auto note{std::make_unique<Document>("note")};
        print_title(*note);
    }
    std::cout << "end of main\n";
    return 0;
}
