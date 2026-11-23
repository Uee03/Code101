#include "app/App.hpp"

#include <spdlog/spdlog.h>

#include <exception>

int main() {
    try {
        spdlog::set_pattern("%H:%M:%S.%e [%^%l%$] %v");
        spdlog::info("Tasks and Teams desktop starting");
        tt::App app;
        const int exitCode = app.run();
        spdlog::info("clean shutdown");
        return exitCode;
    } catch (const std::exception& error) {
        spdlog::critical("fatal: {}", error.what());
        return 1;
    }
}
