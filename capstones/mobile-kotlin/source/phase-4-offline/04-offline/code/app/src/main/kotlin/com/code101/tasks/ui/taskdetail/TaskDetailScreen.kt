package com.code101.tasks.ui.taskdetail

import androidx.compose.foundation.lazy.items
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.ui.res.stringResource
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.code101.tasks.R
import com.code101.tasks.ui.TaskDetailViewModel
import com.code101.tasks.ui.components.*
import java.text.NumberFormat
import java.util.UUID

@Composable
fun TaskDetailScreen(id: String, vm: TaskDetailViewModel, edit: () -> Unit) {
    val state by vm.state.collectAsStateWithLifecycle()
    var body by rememberSaveable { mutableStateOf("") }
    var key by rememberSaveable { mutableStateOf(UUID.randomUUID().toString()) }
    LaunchedEffect(id) { vm.load(id) }
    val task = state.data.tasks.find { it.id == id }
    PageFrame(R.string.task_detail, state) {
        item { Action(R.string.refresh, R.drawable.ic_refresh_cw, !state.busy) { vm.load(id) } }
        if (task != null) item {
            Value(R.string.id, task.id); Value(R.string.project_id, task.projectId)
            Value(R.string.title_field, task.title); Value(R.string.description, task.description)
            Value(R.string.status, wireLabel(task.status)); Value(R.string.priority, wireLabel(task.priority))
            Value(R.string.assignee, task.assigneeId); Value(R.string.due_date, localeDate(task.dueDate))
            Value(R.string.completed_at, localeDate(task.completedAt)); Value(R.string.created_by, task.createdBy)
            Value(R.string.version, NumberFormat.getIntegerInstance().format(task.version))
            Value(R.string.created_at, localeDate(task.createdAt)); Value(R.string.updated_at, localeDate(task.updatedAt))
            Value(R.string.sync_state, wireLabel(task.syncState))
            Action(R.string.edit, R.drawable.ic_list, click = edit)
            Action(R.string.complete, R.drawable.ic_refresh_cw, !state.busy && task.status != "done") { vm.complete(id) }
            Text(stringResource(R.string.comments), style = MaterialTheme.typography.titleLarge)
        }
        items(state.data.comments.filter { it.taskId == id }.sortedBy { it.createdAt }, key = { it.id }) { comment ->
            Value(R.string.author, comment.authorName); Text(comment.body)
            Value(R.string.created_at, localeDate(comment.createdAt)); Text(wireLabel(comment.syncState))
            if (comment.authorId == state.data.me?.id && comment.syncState == "synced") {
                TextButton(onClick = { vm.deleteComment(comment.id) }, enabled = !state.busy) { Text(stringResource(R.string.delete_comment)) }
            }
        }
        item {
            val error = fieldError(state.problem, "/body")
            OutlinedTextField(body, { body = it; key = UUID.randomUUID().toString() },
                label = { Text(stringResource(R.string.comment)) }, isError = error != null,
                supportingText = { error?.let { Text(it) } })
            Action(R.string.add_comment, R.drawable.ic_message_square, !state.busy && body.isNotBlank()) { vm.comment(id, body, key) }
        }
    }
}
