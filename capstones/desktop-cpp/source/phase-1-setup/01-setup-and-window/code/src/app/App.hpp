#pragma once

#include "app/Platform.hpp"

namespace tt {

class App {
public:
    App();

    // Runs until the window is closed or Quit is pressed. Returns the process exit code.
    int run();

private:
    void drawFrame();

    SdlRuntime sdl_;
    Window window_;
    ImGuiLayer imgui_;
    bool quit_{false};
};

}  // namespace tt
