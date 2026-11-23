#include "ui/Screens.hpp"

#include "app/Controller.hpp"

#include <imgui.h>

#include <string>
#include <vector>

namespace tt::ui {
namespace {

constexpr ImVec4 kErrorColour{1.0F, 0.60F, 0.60F, 1.0F};

std::string join(const std::vector<std::string>& values) {
    std::string out;
    for (const auto& value : values) {
        if (!out.empty()) {
            out += ", ";
        }
        out += value;
    }
    return out;
}

void drawTopBar(Controller& controller) {
    const AppState& state = controller.state();
    ImGui::TextUnformatted("Tasks and Teams");
    ImGui::SameLine();
    switch (state.auth) {
        case AuthPhase::SignedOut:
            if (ImGui::Button("Sign in")) {
                controller.signIn();
            }
            break;
        case AuthPhase::SigningIn:
            ImGui::TextUnformatted("Waiting for the browser...");
            ImGui::SameLine();
            if (ImGui::Button("Cancel")) {
                controller.cancelSignIn();
            }
            break;
        case AuthPhase::SignedIn:
            ImGui::TextDisabled("%s", state.me ? state.me->displayName.c_str() : "loading...");
            ImGui::SameLine();
            if (ImGui::Button("Sign out")) {
                controller.signOut();
            }
            break;
    }
}

// Shows every member of the problem: this chapter has no friendly messages yet.
void drawNotice(Controller& controller) {
    const auto& notice = controller.state().notice;
    if (!notice) {
        return;
    }
    ImGui::Separator();
    ImGui::TextColored(kErrorColour, "Problem: %s", notice->title.c_str());
    if (notice->status != 0) {
        ImGui::Text("Status: %d", notice->status);
    }
    if (!notice->detail.empty()) {
        ImGui::TextWrapped("%s", notice->detail.c_str());
    }
    if (!notice->traceId.empty()) {
        ImGui::TextDisabled("trace id %s", notice->traceId.c_str());
    }
    if (ImGui::Button("Dismiss")) {
        controller.dismissNotice();
    }
}

void drawAccount(const Me& me) {
    ImGui::SeparatorText("Signed in");
    ImGui::Text("User: %s (%s)", me.displayName.c_str(), me.username.c_str());
    ImGui::TextWrapped("Roles: %s", join(me.roles).c_str());
    ImGui::TextWrapped("Scopes: %s", join(me.scopes).c_str());
    ImGui::TextUnformatted("Teams:");
    for (const auto& team : me.teams) {
        ImGui::BulletText("%s (%s)", team.name.c_str(), team.role.c_str());
    }
}

}  // namespace

void drawRoot(Controller& controller) {
    const ImGuiViewport* viewport = ImGui::GetMainViewport();
    ImGui::SetNextWindowPos(viewport->WorkPos);
    ImGui::SetNextWindowSize(viewport->WorkSize);
    constexpr ImGuiWindowFlags kFlags =
        ImGuiWindowFlags_NoDecoration | ImGuiWindowFlags_NoMove | ImGuiWindowFlags_NoSavedSettings;
    if (ImGui::Begin("Tasks and Teams", nullptr, kFlags)) {
        drawTopBar(controller);
        drawNotice(controller);
        ImGui::Separator();
        const AppState& state = controller.state();
        if (state.auth == AuthPhase::SignedIn && state.me) {
            drawAccount(*state.me);
        } else if (state.auth == AuthPhase::SignedOut) {
            ImGui::TextWrapped(
                "Sign in to see your teams. The sign-in page opens in your web browser; this app never sees your password.");
        }
    }
    ImGui::End();
}

}  // namespace tt::ui
