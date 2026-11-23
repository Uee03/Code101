#pragma once

#include "app/Theme.hpp"

#include <SDL3/SDL.h>
#include <imgui.h>
#include <imgui_impl_sdl3.h>
#include <imgui_impl_sdlrenderer3.h>

#include <memory>
#include <stdexcept>
#include <string>

namespace tt {

// SDL_Init and SDL_Quit as one object (C++ Core Guidelines R.1 and E.6).
class SdlRuntime {
public:
    SdlRuntime() {
        if (!SDL_Init(SDL_INIT_VIDEO)) {
            throw std::runtime_error(std::string{"SDL_Init failed: "} + SDL_GetError());
        }
    }
    SdlRuntime(const SdlRuntime&) = delete;
    SdlRuntime& operator=(const SdlRuntime&) = delete;
    ~SdlRuntime() { SDL_Quit(); }
};

// A window and its renderer. The renderer is declared last, so it is destroyed first.
class Window {
public:
    Window(const char* title, int width, int height) {
        window_.reset(SDL_CreateWindow(title, width, height, SDL_WINDOW_RESIZABLE | SDL_WINDOW_HIGH_PIXEL_DENSITY));
        if (!window_) {
            throw std::runtime_error(std::string{"SDL_CreateWindow failed: "} + SDL_GetError());
        }
        renderer_.reset(SDL_CreateRenderer(window_.get(), nullptr));
        if (!renderer_) {
            throw std::runtime_error(std::string{"SDL_CreateRenderer failed: "} + SDL_GetError());
        }
        SDL_SetRenderVSync(renderer_.get(), 1);
        SDL_SetWindowMinimumSize(window_.get(), 640, 400);
    }

    [[nodiscard]] SDL_Window* window() const noexcept { return window_.get(); }
    [[nodiscard]] SDL_Renderer* renderer() const noexcept { return renderer_.get(); }

    [[nodiscard]] float displayScale() const noexcept {
        const float scale = SDL_GetWindowDisplayScale(window_.get());
        return scale > 0.0F ? scale : 1.0F;
    }

private:
    struct WindowDeleter {
        void operator()(SDL_Window* window) const noexcept { SDL_DestroyWindow(window); }
    };
    struct RendererDeleter {
        void operator()(SDL_Renderer* renderer) const noexcept { SDL_DestroyRenderer(renderer); }
    };

    std::unique_ptr<SDL_Window, WindowDeleter> window_;
    std::unique_ptr<SDL_Renderer, RendererDeleter> renderer_;
};

// The Dear ImGui context and its two backends for the lifetime of the object.
class ImGuiLayer {
public:
    ImGuiLayer(const Window& window, float scale) {
        IMGUI_CHECKVERSION();
        ImGui::CreateContext();
        ImGuiIO& io = ImGui::GetIO();
        io.ConfigFlags |= ImGuiConfigFlags_NavEnableKeyboard;
        io.IniFilename = nullptr;
        applyTheme(ImGui::GetStyle(), scale);
        if (!ImGui_ImplSDL3_InitForSDLRenderer(window.window(), window.renderer())) {
            ImGui::DestroyContext();
            throw std::runtime_error("Dear ImGui SDL3 backend failed to start");
        }
        if (!ImGui_ImplSDLRenderer3_Init(window.renderer())) {
            ImGui_ImplSDL3_Shutdown();
            ImGui::DestroyContext();
            throw std::runtime_error("Dear ImGui renderer backend failed to start");
        }
    }
    ImGuiLayer(const ImGuiLayer&) = delete;
    ImGuiLayer& operator=(const ImGuiLayer&) = delete;
    ~ImGuiLayer() {
        ImGui_ImplSDLRenderer3_Shutdown();
        ImGui_ImplSDL3_Shutdown();
        ImGui::DestroyContext();
    }

    void processEvent(const SDL_Event& event) { ImGui_ImplSDL3_ProcessEvent(&event); }

    void beginFrame() {
        ImGui_ImplSDLRenderer3_NewFrame();
        ImGui_ImplSDL3_NewFrame();
        ImGui::NewFrame();
    }

    void endFrame(SDL_Renderer* renderer) {
        ImGui::Render();
        SDL_SetRenderDrawColor(renderer, 24, 26, 30, 255);
        SDL_RenderClear(renderer);
        ImGui_ImplSDLRenderer3_RenderDrawData(ImGui::GetDrawData(), renderer);
        SDL_RenderPresent(renderer);
    }
};

}  // namespace tt
