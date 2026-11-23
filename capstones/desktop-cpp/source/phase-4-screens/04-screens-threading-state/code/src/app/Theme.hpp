#pragma once

#include <imgui.h>

namespace tt {

// Colours and spacing for the whole app. `scale` is the display scale reported by SDL.
inline void applyTheme(ImGuiStyle& style, float scale) {
    ImGui::StyleColorsDark(&style);
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
