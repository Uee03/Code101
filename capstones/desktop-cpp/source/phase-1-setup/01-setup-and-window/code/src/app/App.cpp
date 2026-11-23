#include "app/App.hpp"

namespace tt {

App::App() : window_{"Tasks and Teams", 1100, 720}, imgui_{window_, window_.displayScale()} {}

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
        imgui_.beginFrame();
        drawFrame();
        imgui_.endFrame(window_.renderer());
    }
    return 0;
}

void App::drawFrame() {
    const ImGuiViewport* viewport = ImGui::GetMainViewport();
    ImGui::SetNextWindowPos(viewport->WorkPos);
    ImGui::SetNextWindowSize(viewport->WorkSize);
    constexpr ImGuiWindowFlags kFlags =
        ImGuiWindowFlags_NoDecoration | ImGuiWindowFlags_NoMove | ImGuiWindowFlags_NoSavedSettings;
    if (ImGui::Begin("Tasks and Teams", nullptr, kFlags)) {
        ImGui::TextUnformatted("Tasks and Teams");
        ImGui::Separator();
        ImGui::TextUnformatted("Setup ready: SDL3 and Dear ImGui are running.");
        const int sdl = SDL_GetVersion();
        ImGui::Text("SDL %d.%d.%d, Dear ImGui %s", SDL_VERSIONNUM_MAJOR(sdl), SDL_VERSIONNUM_MINOR(sdl),
                    SDL_VERSIONNUM_MICRO(sdl), IMGUI_VERSION);
        ImGui::Text("%.1f frames per second", ImGui::GetIO().Framerate);
        if (ImGui::Button("Quit")) {
            quit_ = true;
        }
    }
    ImGui::End();
}

}  // namespace tt
