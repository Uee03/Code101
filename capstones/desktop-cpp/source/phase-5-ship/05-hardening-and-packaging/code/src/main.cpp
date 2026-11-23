#include "app/App.hpp"
#include "core/Config.hpp"

#include <SDL3/SDL.h>
#include <spdlog/cfg/env.h>
#include <spdlog/sinks/rotating_file_sink.h>
#include <spdlog/sinks/stdout_color_sinks.h>
#include <spdlog/spdlog.h>

#include <exception>
#include <memory>
#include <string>
#include <utility>
#include <vector>

namespace {

// Console plus a rotating file (1 MiB, three files) in the user's preferences folder.
// Request lines hold method, URL and status only; tokens and bodies are never logged.
void initLogging() {
    std::vector<spdlog::sink_ptr> sinks{std::make_shared<spdlog::sinks::stdout_color_sink_mt>()};
    const std::unique_ptr<char, decltype(&SDL_free)> folder{SDL_GetPrefPath("code101", "tasks-desktop"), &SDL_free};
    if (folder) {
        try {
            sinks.push_back(std::make_shared<spdlog::sinks::rotating_file_sink_mt>(std::string{folder.get()} + "tasks.log",
                                                                                   1024U * 1024U, 3U));
        } catch (const spdlog::spdlog_ex&) {
            // No log file: the console sink is enough.
        }
    }
    auto logger = std::make_shared<spdlog::logger>("tasks", sinks.begin(), sinks.end());
    logger->set_pattern("%Y-%m-%d %H:%M:%S.%e [%^%l%$] %v");
    logger->flush_on(spdlog::level::warn);
    spdlog::set_default_logger(std::move(logger));
    spdlog::cfg::load_env_levels();
}

}  // namespace

int main() {
    try {
        initLogging();
        auto config = tt::loadConfig();
        if (!config) {
            spdlog::critical("{}: {}", config.error().title, config.error().detail);
            return 2;
        }
        spdlog::info("Tasks and Teams desktop starting, API at {}", config->apiBaseUrl);
        tt::App app{std::move(*config)};
        const int exitCode = app.run();
        spdlog::info("clean shutdown");
        spdlog::shutdown();
        return exitCode;
    } catch (const std::exception& error) {
        spdlog::critical("fatal: {}", error.what());
        return 1;
    }
}
