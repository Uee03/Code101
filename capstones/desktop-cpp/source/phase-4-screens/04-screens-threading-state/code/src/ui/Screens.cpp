#include "ui/Screens.hpp"

#include "app/Controller.hpp"
#include "core/ProblemText.hpp"

#include <imgui.h>

#include <algorithm>
#include <string>

namespace tt::ui {
namespace {

constexpr ImVec4 kErrorColour{1.0F, 0.60F, 0.60F, 1.0F};

// Sizes are multiples of the font size, so they follow the display scale.
float em(float factor) { return ImGui::GetFontSize() * factor; }

// A modal dialog that opens when `wanted` becomes true and closes when it becomes false.
template <class Body>
void drawModal(const char* name, bool wanted, Body body) {
    if (wanted && !ImGui::IsPopupOpen(name)) {
        ImGui::OpenPopup(name);
    }
    if (ImGui::BeginPopupModal(name, nullptr, ImGuiWindowFlags_AlwaysAutoResize)) {
        if (wanted) {
            body();
        } else {
            ImGui::CloseCurrentPopup();
        }
        ImGui::EndPopup();
    }
}

void append(std::string& line, const std::string& part) {
    if (part.empty()) {
        return;
    }
    if (!line.empty()) {
        line += ", ";
    }
    line += part;
}

std::string technicalLine(const Problem& problem) {
    std::string line;
    append(line, problem.status != 0 ? "status " + std::to_string(problem.status) : std::string{});
    append(line, problem.type.empty() ? std::string{} : "type " + problemSlug(problem));
    append(line, problem.traceId.empty() ? std::string{} : "trace id " + problem.traceId);
    return line;
}

std::string roleIn(const std::optional<Me>& me, const std::string& teamId) {
    if (me) {
        for (const auto& team : me->teams) {
            if (team.teamId == teamId) {
                return team.role;
            }
        }
    }
    return {};
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

// A friendly sentence first, the technical members below it, then the invalid fields.
void drawNotice(Controller& controller) {
    const auto& notice = controller.state().notice;
    if (!notice) {
        return;
    }
    ImGui::Separator();
    ImGui::TextColored(kErrorColour, "Problem: %s", userMessage(*notice).c_str());
    const std::string technical = technicalLine(*notice);
    if (!technical.empty()) {
        ImGui::TextDisabled("%s", technical.c_str());
    }
    if (!notice->detail.empty()) {
        ImGui::TextWrapped("%s", notice->detail.c_str());
    }
    for (const auto& error : notice->errors) {
        ImGui::BulletText("%s: %s", error.pointer.c_str(), error.detail.c_str());
    }
    if (ImGui::Button("Dismiss")) {
        controller.dismissNotice();
    }
}

void drawNav(Controller& controller) {
    AppState& state = controller.state();
    ImGui::SeparatorText("Teams");
    for (const auto& team : state.teams.items) {
        ImGui::PushID(team.id.c_str());
        const std::string role = roleIn(state.me, team.id);
        const std::string label = team.name + (role.empty() ? "" : " (" + role + ")");
        if (ImGui::Selectable(label.c_str(), team.id == state.teamId)) {
            controller.selectTeam(team.id);
        }
        ImGui::PopID();
    }
    if (state.teams.phase == LoadPhase::Loading) {
        ImGui::TextDisabled("Loading teams...");
    } else if (state.teams.phase == LoadPhase::Ready && state.teams.items.empty()) {
        ImGui::TextDisabled("You are not in any team yet.");
    } else if (state.teams.nextCursor && ImGui::Button("More teams")) {
        controller.loadTeams(true);
    }

    if (state.teamId.empty()) {
        return;
    }
    ImGui::SeparatorText("Projects");
    for (const auto& project : state.projects.items) {
        ImGui::PushID(project.id.c_str());
        const std::string label = project.key + "  " + project.name;
        if (ImGui::Selectable(label.c_str(), project.id == state.projectId)) {
            controller.selectProject(project.id);
        }
        ImGui::PopID();
    }
    if (state.projects.phase == LoadPhase::Loading) {
        ImGui::TextDisabled("Loading projects...");
    } else if (state.projects.phase == LoadPhase::Ready && state.projects.items.empty()) {
        ImGui::TextDisabled("This team has no projects.");
    } else if (state.projects.nextCursor && ImGui::Button("More projects")) {
        controller.loadProjects(true);
    }
}

void drawTasks(Controller& controller) {
    AppState& state = controller.state();
    if (state.projectId.empty()) {
        ImGui::TextDisabled("Choose a team and a project on the left.");
        return;
    }

    bool filtersChanged = false;
    for (std::size_t i = 0; i < kStatuses.size(); ++i) {
        if (i != 0) {
            ImGui::SameLine();
        }
        filtersChanged |= ImGui::Checkbox(kStatuses[i], &state.statusFilter[i]);
    }
    ImGui::SetNextItemWidth(em(14.0F));
    filtersChanged |= ImGui::InputTextWithHint("##search", "title contains, Enter", state.search.data(),
                                               state.search.size(), ImGuiInputTextFlags_EnterReturnsTrue);
    ImGui::SameLine();
    ImGui::SetNextItemWidth(em(10.0F));
    filtersChanged |= ImGui::Combo("sort", &state.sortIndex, kSorts.data(), static_cast<int>(kSorts.size()));
    if (filtersChanged) {
        controller.loadTasks(false);
    }
    if (ImGui::Button("New task")) {
        controller.openCreateForm();
    }
    ImGui::SameLine();
    if (ImGui::Button("Reload")) {
        controller.loadTasks(false);
    }

    const float height = std::max(ImGui::GetContentRegionAvail().y - ImGui::GetFrameHeightWithSpacing() * 2.0F, em(6.0F));
    constexpr ImGuiTableFlags kTableFlags =
        ImGuiTableFlags_RowBg | ImGuiTableFlags_Borders | ImGuiTableFlags_Resizable | ImGuiTableFlags_ScrollY;
    if (ImGui::BeginTable("tasks", 6, kTableFlags, ImVec2{0.0F, height})) {
        ImGui::TableSetupScrollFreeze(0, 1);
        ImGui::TableSetupColumn("Title", ImGuiTableColumnFlags_WidthStretch, 3.0F);
        ImGui::TableSetupColumn("Status");
        ImGui::TableSetupColumn("Priority");
        ImGui::TableSetupColumn("Due");
        ImGui::TableSetupColumn("Version");
        ImGui::TableSetupColumn("Actions");
        ImGui::TableHeadersRow();
        for (const auto& task : state.tasks.items) {
            ImGui::PushID(task.id.c_str());
            ImGui::TableNextRow();
            ImGui::TableNextColumn();
            ImGui::TextUnformatted(task.title.c_str());
            ImGui::TableNextColumn();
            ImGui::TextUnformatted(task.status.c_str());
            ImGui::TableNextColumn();
            ImGui::TextUnformatted(task.priority.c_str());
            ImGui::TableNextColumn();
            ImGui::TextUnformatted(task.dueDate ? task.dueDate->c_str() : "-");
            ImGui::TableNextColumn();
            ImGui::Text("%d", task.version);
            ImGui::TableNextColumn();
            if (ImGui::SmallButton("Edit")) {
                controller.openEditForm(task);
            }
            ImGui::SameLine();
            if (ImGui::SmallButton("Delete")) {
                controller.askDelete(task);
            }
            ImGui::PopID();
        }
        ImGui::EndTable();
    }

    if (state.tasks.phase == LoadPhase::Loading) {
        ImGui::TextDisabled("Loading tasks...");
    } else if (state.tasks.phase == LoadPhase::Ready && state.tasks.items.empty()) {
        ImGui::TextDisabled("No tasks match.");
    } else if (state.tasks.nextCursor && ImGui::Button("More tasks")) {
        controller.loadTasks(true);
    }
}

void drawFieldError(const TaskForm& form, const char* pointer) {
    for (const auto& error : form.errors) {
        if (error.pointer == pointer) {
            ImGui::TextColored(kErrorColour, "%s", error.detail.c_str());
        }
    }
}

void drawForm(Controller& controller) {
    TaskForm& form = controller.state().form;
    drawModal("Task", form.open, [&] {
        ImGui::TextUnformatted(form.creating ? "New task" : "Edit task");
        ImGui::SetNextItemWidth(em(32.0F));
        ImGui::InputText("Title", form.title.data(), form.title.size());
        drawFieldError(form, "/title");
        ImGui::InputTextMultiline("Description", form.description.data(), form.description.size(),
                                  ImVec2{em(32.0F), em(8.0F)});
        drawFieldError(form, "/description");
        ImGui::BeginDisabled(form.creating);
        ImGui::Combo("Status", &form.status, kStatuses.data(), static_cast<int>(kStatuses.size()));
        ImGui::EndDisabled();
        ImGui::Combo("Priority", &form.priority, kPriorities.data(), static_cast<int>(kPriorities.size()));
        ImGui::InputTextWithHint("Due date", "YYYY-MM-DD", form.dueDate.data(), form.dueDate.size());
        drawFieldError(form, "/dueDate");
        ImGui::Separator();
        ImGui::BeginDisabled(form.saving);
        if (ImGui::Button("Save")) {
            controller.saveForm();
        }
        ImGui::EndDisabled();
        ImGui::SameLine();
        if (ImGui::Button("Cancel")) {
            controller.closeForm();
        }
        if (form.saving) {
            ImGui::SameLine();
            ImGui::TextUnformatted("Saving...");
        }
    });
}

void drawConflict(Controller& controller) {
    const AppState& state = controller.state();
    drawModal("Conflict", state.conflict.has_value() && !state.form.open, [&] {
        ImGui::TextWrapped("Someone else changed \"%s\" while you were editing it.", state.conflict->title.c_str());
        ImGui::TextWrapped("Keep my change: load the current version and send my change again. Reload: drop my change.");
        if (ImGui::Button("Keep my change")) {
            controller.keepMine();
        }
        ImGui::SameLine();
        if (ImGui::Button("Reload")) {
            controller.dropConflict();
        }
    });
}

void drawDelete(Controller& controller) {
    const AppState& state = controller.state();
    drawModal("Delete task", state.pendingDelete.has_value(), [&] {
        ImGui::TextWrapped("Delete \"%s\"? This cannot be undone.", state.pendingDelete->title.c_str());
        if (ImGui::Button("Delete")) {
            controller.confirmDelete();
        }
        ImGui::SameLine();
        if (ImGui::Button("Keep")) {
            controller.cancelDelete();
        }
    });
}

void drawWorkspace(Controller& controller) {
    if (ImGui::BeginChild("nav", ImVec2{em(22.0F), 0.0F}, ImGuiChildFlags_Borders)) {
        drawNav(controller);
    }
    ImGui::EndChild();
    ImGui::SameLine();
    if (ImGui::BeginChild("tasks-pane", ImVec2{0.0F, 0.0F}, ImGuiChildFlags_Borders)) {
        drawTasks(controller);
    }
    ImGui::EndChild();
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
        switch (controller.state().auth) {
            case AuthPhase::SignedOut:
                ImGui::TextWrapped("Sign in to see your teams. The sign-in page opens in your web browser; this app never "
                                   "sees your password.");
                break;
            case AuthPhase::SigningIn:
                ImGui::TextWrapped("Finish signing in in your web browser, then come back to this window.");
                break;
            case AuthPhase::SignedIn:
                drawWorkspace(controller);
                break;
        }
        drawForm(controller);
        drawConflict(controller);
        drawDelete(controller);
    }
    ImGui::End();
}

}  // namespace tt::ui
