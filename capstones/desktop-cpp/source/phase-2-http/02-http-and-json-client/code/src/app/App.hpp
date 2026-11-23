#pragma once

#include "api/ApiClient.hpp"
#include "app/Platform.hpp"
#include "core/Config.hpp"
#include "net/CprTransport.hpp"

#include <string>

namespace tt {

class App {
public:
    explicit App(Config config);

    // Runs until the window is closed or Quit is pressed. Returns the process exit code.
    int run();

private:
    void drawFrame();
    void drawProbe();

    SdlRuntime sdl_;
    Window window_;
    ImGuiLayer imgui_;
    Config config_;
    CprTransport transport_;
    ApiClient api_;
    std::string probeText_{"Press a button."};
    bool quit_{false};
};

}  // namespace tt
