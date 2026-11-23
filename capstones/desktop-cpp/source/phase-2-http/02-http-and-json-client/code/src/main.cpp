#include "app/App.hpp"
#include "core/Config.hpp"

#include <spdlog/cfg/env.h>
#include <spdlog/spdlog.h>

#include <exception>

int main() {
    try {
        spdlog::cfg::load_env_levels();
        spdlog::set_pattern("%H:%M:%S.%e [%^%l%$] %v");
        spdlog::info("Tasks and Teams desktop starting");
        tt::App app{tt::loadConfig()};
        const int exitCode = app.run();
        spdlog::info("clean shutdown");
        return exitCode;
    } catch (const std::exception& error) {
        spdlog::critical("fatal: {}", error.what());
        return 1;
    }
}
