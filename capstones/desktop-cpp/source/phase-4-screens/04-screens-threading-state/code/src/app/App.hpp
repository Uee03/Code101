#pragma once

#include "app/Controller.hpp"
#include "app/Platform.hpp"
#include "core/Config.hpp"
#include "net/CprTransport.hpp"

namespace tt {

class App {
public:
    explicit App(Config config);

    // Runs until the window is closed. Returns the process exit code.
    int run();

private:
    SdlRuntime sdl_;
    Window window_;
    ImGuiLayer imgui_;
    Config config_;
    CprTransport transport_;
    Controller controller_;  // after transport_: it uses it; its destructor joins the worker threads
    bool quit_{false};
};

}  // namespace tt
