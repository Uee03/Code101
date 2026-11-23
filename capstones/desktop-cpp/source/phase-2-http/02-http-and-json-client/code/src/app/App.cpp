#include "app/App.hpp"

#include <utility>

namespace tt {
namespace {

const char* kindName(ErrorKind kind) {
    switch (kind) {
        case ErrorKind::Network: return "network";
        case ErrorKind::Http: return "http";
        case ErrorKind::Parse: return "parse";
        case ErrorKind::Auth: return "auth";
        case ErrorKind::Config: return "config";
        case ErrorKind::Cancelled: return "cancelled";
    }
    return "?";
}

// Every field of the problem, so that you can see what the server really sent.
std::string describe(const Problem& problem) {
    std::string text = std::string{"kind: "} + kindName(problem.kind) + "\n";
    text += "status: " + std::to_string(problem.status) + "\n";
    text += "type: " + problem.type + "\n";
    text += "title: " + problem.title + "\n";
    text += "detail: " + problem.detail + "\n";
    text += "traceId: " + problem.traceId + "\n";
    for (const auto& error : problem.errors) {
        text += "field " + error.pointer + ": " + error.detail + "\n";
    }
    return text;
}

}  // namespace

App::App(Config config)
    : window_{"Tasks and Teams", 1100, 720},
      imgui_{window_, window_.displayScale()},
      config_{std::move(config)},
      api_{transport_, config_.apiBaseUrl, [](std::stop_token) { return Result<std::string>(std::string{}); }} {}

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
        drawProbe();
        ImGui::Separator();
        ImGui::Text("%.1f frames per second", ImGui::GetIO().Framerate);
        if (ImGui::Button("Quit")) {
            quit_ = true;
        }
    }
    ImGui::End();
}

void App::drawProbe() {
    ImGui::SeparatorText("Probe the API");
    ImGui::TextWrapped("API base URL: %s", config_.apiBaseUrl.c_str());
    ImGui::TextDisabled("These buttons call the backend on the UI thread, so the window freezes until the answer or the timeout. Chapter 04 fixes that.");
    if (ImGui::Button("GET /health")) {
        const auto health = api_.health();
        probeText_ = health ? "status: " + health->status + "\ndatabase: " + health->database : describe(health.error());
    }
    ImGui::SameLine();
    if (ImGui::Button("GET /v1/me without a token")) {
        const auto me = api_.me();
        probeText_ = me ? "Hello " + me->username : describe(me.error());
    }
    ImGui::TextWrapped("%s", probeText_.c_str());
}

}  // namespace tt
