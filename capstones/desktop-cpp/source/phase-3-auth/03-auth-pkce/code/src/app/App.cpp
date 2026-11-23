#include "app/App.hpp"

#include "ui/Screens.hpp"

#include <utility>

namespace tt {

App::App(Config config)
    : window_{"Tasks and Teams", 1100, 720},
      imgui_{window_, window_.displayScale()},
      config_{std::move(config)},
      controller_{config_, transport_, [](const std::string& url) { return SDL_OpenURL(url.c_str()); }} {}

int App::run() {
    while (!quit_) {
        SDL_Event event;
        while (SDL_PollEvent(&event)) {
            imgui_.processEvent(event);
            const bool closeRequested = event.type == SDL_EVENT_QUIT ||
                                        (event.type == SDL_EVENT_WINDOW_CLOSE_REQUESTED &&
                                         event.window.windowID == SDL_GetWindowID(window_.window()));
            if (closeRequested) {
                quit_ = true;
            }
        }
        if ((SDL_GetWindowFlags(window_.window()) & SDL_WINDOW_MINIMIZED) != 0) {
            SDL_Delay(50);
            continue;
        }
        controller_.pump();  // apply what the workers finished since the last frame
        imgui_.beginFrame();
        ui::drawRoot(controller_);
        imgui_.endFrame(window_.renderer());
    }
    return 0;
}

}  // namespace tt
