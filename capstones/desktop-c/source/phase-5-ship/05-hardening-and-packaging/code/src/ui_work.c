#include <string.h>

#include "ui.h"

/* Same order as TS_STATUSES and TS_PRIORITIES in model.c: the combo index is the array index. */
static const char *STATUS_ITEMS[5] = {"todo", "in_progress", "blocked", "done", "cancelled"};
static const char *PRIORITY_ITEMS[4] = {"low", "medium", "high", "urgent"};
static const char *FILTER_ITEMS[6] = {"all statuses", "todo", "in_progress", "blocked", "done", "cancelled"};

static void teams_group(struct nk_context *nk, ts_store *st) {
    if (!nk_group_begin(nk, "Teams and projects", NK_WINDOW_BORDER | NK_WINDOW_TITLE)) return;

    nk_layout_row_dynamic(nk, 26, 1);
    for (size_t i = 0; i < st->teams.items.len; i++) {
        const ts_team *t = ts_vec_at(&st->teams.items, i);
        char label[160];
        ts_setf(label, sizeof label, "%s (%d members)", t->name, t->member_count);
        nk_bool selected = strcmp(t->id, st->team_id) == 0;
        if (nk_selectable_label(nk, label, NK_TEXT_LEFT, &selected) && selected) ts_store_select_team(st, t->id);
    }
    if (st->teams.items.len == 0) nk_label(nk, ts_store_busy(st) ? "Loading teams..." : "No teams.", NK_TEXT_LEFT);

    if (st->team_id[0] != '\0') {
        nk_label(nk, "Projects", NK_TEXT_LEFT);
        for (size_t i = 0; i < st->projects.items.len; i++) {
            const ts_project *p = ts_vec_at(&st->projects.items, i);
            char label[200];
            ts_setf(label, sizeof label, "%s  %s%s", p->key, p->name, p->archived ? "  [archived]" : "");
            nk_bool selected = strcmp(p->id, st->project_id) == 0;
            if (nk_selectable_label(nk, label, NK_TEXT_LEFT, &selected) && selected) {
                ts_store_select_project(st, p->id);
            }
        }
        if (st->projects.items.len == 0) nk_label(nk, ts_store_busy(st) ? "Loading projects..." : "No projects.", NK_TEXT_LEFT);
    }
    nk_group_end(nk);
}

static void tasks_group(struct nk_context *nk, ts_store *st) {
    static const float columns[3] = {0.58f, 0.22f, 0.20f};
    if (!nk_group_begin(nk, "Tasks", NK_WINDOW_BORDER | NK_WINDOW_TITLE)) return;

    if (st->project_id[0] == '\0') {
        nk_layout_row_dynamic(nk, 26, 1);
        nk_label(nk, "Choose a project.", NK_TEXT_LEFT);
        nk_group_end(nk);
        return;
    }

    nk_layout_row_dynamic(nk, 30, 3);
    int filter = nk_combo(nk, FILTER_ITEMS, 6, st->status_filter, 24, nk_vec2(200, 190));
    if (filter != st->status_filter) ts_store_set_filter(st, filter);
    if (nk_button_label(nk, "New task")) ts_store_form_new(st);
    if (nk_button_label(nk, "Reload")) {
        char id[TS_ID_LEN];
        ts_copy(id, sizeof id, st->project_id);
        st->project_id[0] = '\0'; /* select_project ignores the project that is already selected */
        ts_store_select_project(st, id);
    }

    nk_layout_row(nk, NK_DYNAMIC, 26, 3, columns);
    for (size_t i = 0; i < st->tasks.items.len; i++) {
        const ts_task *t = ts_vec_at(&st->tasks.items, i);
        nk_bool selected = st->form.open && st->form.editing && strcmp(st->form.task_id, t->id) == 0;
        if (nk_selectable_label(nk, t->title, NK_TEXT_LEFT, &selected) && selected) ts_store_form_edit(st, i);
        nk_label(nk, t->status, NK_TEXT_LEFT);
        nk_label(nk, t->priority, NK_TEXT_LEFT);
    }

    nk_layout_row_dynamic(nk, 30, 1);
    if (st->tasks.next_cursor[0] != '\0') {
        if (nk_button_label(nk, st->loading_more ? "Loading..." : "Load more")) ts_store_load_more(st);
    } else if (st->tasks.items.len == 0) {
        nk_label(nk, ts_store_busy(st) ? "Loading tasks..." : "No tasks match.", NK_TEXT_LEFT);
    } else {
        nk_labelf(nk, NK_TEXT_LEFT, "%zu tasks, end of list", st->tasks.items.len);
    }
    nk_group_end(nk);
}

static void show_difference(struct nk_context *nk, const char *name, const char *mine, const char *theirs) {
    if (strcmp(mine, theirs) == 0) return;
    nk_labelf(nk, NK_TEXT_LEFT, "%s, mine: %s", name, mine);
    nk_labelf(nk, NK_TEXT_LEFT, "%s, theirs: %s", name, theirs);
}

static void conflict_panel(struct nk_context *nk, ts_store *st) {
    ts_form *f = &st->form;
    ts_task_draft theirs;
    ts_draft_from_task(&theirs, &f->theirs);

    nk_layout_row_dynamic(nk, 26, 1);
    nk_labelf(nk, NK_TEXT_LEFT, "Conflict: someone saved version %ld first.", f->theirs.version);
    show_difference(nk, "Title", f->draft.title, theirs.title);
    if (strcmp(f->draft.description, theirs.description) != 0) nk_label(nk, "Description differs.", NK_TEXT_LEFT);
    show_difference(nk, "Status", STATUS_ITEMS[f->status_index], theirs.status);
    show_difference(nk, "Priority", PRIORITY_ITEMS[f->priority_index], theirs.priority);
    show_difference(nk, "Due", f->draft.due_date, theirs.due_date);

    nk_layout_row_dynamic(nk, 34, 2);
    if (nk_button_label(nk, "Keep mine")) ts_store_form_keep_mine(st);
    if (nk_button_label(nk, "Take theirs")) ts_store_form_take_theirs(st);
}

static void form_group(struct nk_context *nk, ts_store *st) {
    if (!nk_group_begin(nk, "Task", NK_WINDOW_BORDER | NK_WINDOW_TITLE)) return;
    ts_form *f = &st->form;

    nk_layout_row_dynamic(nk, 26, 1);
    if (!f->open) {
        nk_label(nk, "Select a task, or press New task.", NK_TEXT_LEFT);
        nk_group_end(nk);
        return;
    }

    if (f->editing) {
        nk_labelf(nk, NK_TEXT_LEFT, "Edit task (version %ld)", f->base_version);
    } else {
        nk_label(nk, "New task", NK_TEXT_LEFT);
    }

    nk_label(nk, "Title", NK_TEXT_LEFT);
    nk_edit_string_zero_terminated(nk, NK_EDIT_FIELD, f->draft.title, (int)sizeof f->draft.title, nk_filter_default);

    nk_label(nk, "Description", NK_TEXT_LEFT);
    if (f->description_locked) {
        nk_layout_row_dynamic(nk, 52, 1);
        nk_label_wrap(nk, "The description is too long for this form. It is shown cut and is left unchanged.");
        nk_layout_row_dynamic(nk, 26, 1);
    } else {
        nk_layout_row_dynamic(nk, 100, 1);
        nk_edit_string_zero_terminated(nk, NK_EDIT_BOX, f->draft.description, (int)sizeof f->draft.description,
                                       nk_filter_default);
        nk_layout_row_dynamic(nk, 26, 1);
    }

    nk_label(nk, "Priority", NK_TEXT_LEFT);
    f->priority_index = nk_combo(nk, PRIORITY_ITEMS, 4, f->priority_index, 24, nk_vec2(200, 130));
    if (f->editing) {
        nk_label(nk, "Status", NK_TEXT_LEFT);
        f->status_index = nk_combo(nk, STATUS_ITEMS, 5, f->status_index, 24, nk_vec2(200, 160));
    }
    nk_label(nk, "Due date (YYYY-MM-DD, empty = none)", NK_TEXT_LEFT);
    nk_edit_string_zero_terminated(nk, NK_EDIT_FIELD, f->draft.due_date, (int)sizeof f->draft.due_date, nk_filter_default);

    nk_layout_row_dynamic(nk, 34, 2);
    if (nk_button_label(nk, "Save")) ts_store_form_save(st);
    if (nk_button_label(nk, "Close")) {
        ts_store_form_close(st);
        nk_group_end(nk);
        return;
    }
    if (f->editing) {
        if (nk_button_label(nk, "Mark as done")) ts_store_form_complete(st);
        if (nk_button_label(nk, f->delete_armed ? "Really delete" : "Delete")) ts_store_form_delete(st);
    }
    if (f->conflict) conflict_panel(nk, st);
    nk_group_end(nk);
}

void ts_ui_workspace(struct nk_context *nk, ts_store *st, float body_h) {
    static const float ratio[3] = {0.22f, 0.40f, 0.38f};
    nk_layout_row(nk, NK_DYNAMIC, body_h, 3, ratio);
    teams_group(nk, st);
    tasks_group(nk, st);
    form_group(nk, st);
}
