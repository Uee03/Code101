#pragma once

#include <SDL3/SDL.h>
#include <imgui.h>

#include <string_view>

namespace tt {

// Chooses the colour set from the environment variable TASKS_THEME ("light", "contrast" or anything else for dark).
inline void applyTheme(ImGuiStyle& style, float scale) {
    const char* raw = SDL_getenv("TASKS_THEME");
    const std::string_view theme = raw != nullptr ? raw : "";
    if (theme == "light") {
        ImGui::StyleColorsLight(&style);
    } else {
        ImGui::StyleColorsDark(&style);
    }
    style.WindowRounding = 0.0F;
    style.FrameRounding = 4.0F;
    style.ItemSpacing = ImVec2{8.0F, 6.0F};
    style.Colors[ImGuiCol_Button] = ImVec4{0.20F, 0.45F, 0.80F, 1.0F};
    style.Colors[ImGuiCol_ButtonHovered] = ImVec4{0.28F, 0.55F, 0.92F, 1.0F};
    style.Colors[ImGuiCol_ButtonActive] = ImVec4{0.16F, 0.38F, 0.70F, 1.0F};
    if (theme == "contrast") {
        style.Colors[ImGuiCol_WindowBg] = ImVec4{0.0F, 0.0F, 0.0F, 1.0F};
        style.Colors[ImGuiCol_Text] = ImVec4{1.0F, 1.0F, 1.0F, 1.0F};
        style.Colors[ImGuiCol_Button] = ImVec4{0.0F, 0.0F, 0.0F, 1.0F};
        style.Colors[ImGuiCol_ButtonHovered] = ImVec4{0.35F, 0.35F, 0.0F, 1.0F};
        style.Colors[ImGuiCol_ButtonActive] = ImVec4{1.0F, 1.0F, 0.0F, 1.0F};
        style.Colors[ImGuiCol_Border] = ImVec4{1.0F, 1.0F, 0.0F, 1.0F};
        style.FrameBorderSize = 1.0F;
    }
    style.ScaleAllSizes(scale);
    style.FontScaleDpi = scale;
}

}  // namespace tt
