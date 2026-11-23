#pragma once

#include <imgui.h>

namespace tt {

// Exercise: make the theme selectable.
// Rung 1 (guided): change the three button colours to another accent colour.
// Rung 2 (partial): read the environment variable TASKS_THEME with SDL_getenv (include <SDL3/SDL.h>).
//   "light" selects ImGui::StyleColorsLight, anything else keeps ImGui::StyleColorsDark.
// Rung 3 (open): add "contrast" with black, white and yellow only, and work out the contrast ratio of your text colours.
inline void applyTheme(ImGuiStyle& style, float scale) {
    ImGui::StyleColorsDark(&style);  // TODO rung 2: choose by TASKS_THEME
    style.WindowRounding = 0.0F;
    style.FrameRounding = 4.0F;
    style.ItemSpacing = ImVec2{8.0F, 6.0F};
    style.Colors[ImGuiCol_Button] = ImVec4{0.20F, 0.45F, 0.80F, 1.0F};
    style.Colors[ImGuiCol_ButtonHovered] = ImVec4{0.28F, 0.55F, 0.92F, 1.0F};
    style.Colors[ImGuiCol_ButtonActive] = ImVec4{0.16F, 0.38F, 0.70F, 1.0F};
    style.ScaleAllSizes(scale);
    style.FontScaleDpi = scale;
}

}  // namespace tt
