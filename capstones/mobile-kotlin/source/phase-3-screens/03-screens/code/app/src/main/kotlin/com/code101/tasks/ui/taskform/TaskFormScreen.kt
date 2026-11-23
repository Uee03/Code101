package com.code101.tasks.ui.taskform

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.verticalScroll
import androidx.compose.foundation.rememberScrollState
import androidx.compose.material3.*
import androidx.compose.foundation.selection.toggleable
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.compose.runtime.*
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.ui.res.stringResource
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.code101.tasks.R
import com.code101.tasks.domain.model.*
import com.code101.tasks.ui.TaskFormViewModel
import com.code101.tasks.ui.components.*
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json
import java.util.UUID

@OptIn(ExperimentalMaterial3Api::class, ExperimentalLayoutApi::class)
@Composable
fun TaskFormScreen(projectId: String, taskId: String?, vm: TaskFormViewModel, saved: () -> Unit) {
    val state by vm.state.collectAsStateWithLifecycle()
    var originalJson by rememberSaveable { mutableStateOf<String?>(null) }
    var title by rememberSaveable { mutableStateOf("") }
    var description by rememberSaveable { mutableStateOf("") }
    var status by rememberSaveable { mutableStateOf("todo") }
    var priority by rememberSaveable { mutableStateOf("medium") }
    var assignee by rememberSaveable { mutableStateOf("") }
    var due by rememberSaveable { mutableStateOf("") }
    val key = rememberSaveable { UUID.randomUUID().toString() }
    val task = state.data.tasks.find { it.id == taskId }
    val formProblem = state.problem ?: state.data.outbox.firstOrNull {
        it.entityId == taskId && it.state == "failed"
    }?.problem
    val original = originalJson?.let { Json.decodeFromString<TaskItem>(it) }
    LaunchedEffect(taskId) { if (taskId != null) vm.load(taskId) }
    LaunchedEffect(task?.id) {
        if (task != null && originalJson == null) {
            originalJson = Json.encodeToString(task)
            title = task.title; description = task.description; status = task.status
            priority = task.priority; assignee = task.assigneeId.orEmpty(); due = task.dueDate.orEmpty()
        }
    }
    LaunchedEffect(vm) { vm.saved.collect { saved() } }
    PageFrame(R.string.task_form, state) {
        item {
            EditField("title", title, { title = it }, formProblem)
            EditField("description", description, { description = it }, formProblem)
            EditField("assigneeId", assignee, { assignee = it }, formProblem)
            EditField("dueDate", due, { due = it }, formProblem)
            Text(stringResource(R.string.priority))
            FlowRow { listOf("low", "medium", "high", "urgent").forEach { value ->
                FilterChip(priority == value, { priority = value }, label = { Text(wireLabel(value)) })
            } }
            if (taskId != null) {
                Text(stringResource(R.string.status))
                FlowRow { listOf("todo", "in_progress", "blocked", "done", "cancelled").forEach { value ->
                    FilterChip(status == value, { status = value }, label = { Text(wireLabel(value)) })
                } }
            }
            Action(R.string.save, R.drawable.ic_plus, !state.busy && (taskId == null || original != null)) {
                vm.save(task?.projectId ?: projectId, taskId, key,
                    TaskDraft(title, description, status, priority, assignee.ifBlank { null }, due.ifBlank { null }), original)
            }
        }
    }
    val conflict = state.data.outbox.firstOrNull { it.entityId == taskId && it.state == "conflict" }
    var showConflict by remember(conflict?.id) { mutableStateOf(conflict != null) }
    if (showConflict && conflict != null && task != null) ConflictSheet(task, conflict,
        dismiss = { showConflict = false }, resolve = { keep -> vm.resolve(task.id, keep) })
}
@Composable
private fun EditField(field: String, value: String, change: (String) -> Unit, problem: ApiProblem?) {
    val error = fieldError(problem, "/" + field)
    OutlinedTextField(value, change, label = { Text(fieldLabel(field)) },
        modifier = Modifier.fillMaxWidth().padding(vertical = 4.dp), isError = error != null,
        supportingText = { error?.let { Text(it) } })
}
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ConflictSheet(task: TaskItem, write: PendingWrite, dismiss: () -> Unit, resolve: (Set<String>) -> Unit) {
    var selected by remember(write.id) { mutableStateOf(write.payload.keys) }
    val server = task.server
    val theirs = mapOf("title" to server?.title, "description" to server?.description,
        "status" to server?.status, "priority" to server?.priority, "assigneeId" to server?.assigneeId,
        "dueDate" to server?.dueDate)
    ModalBottomSheet(onDismissRequest = dismiss) {
        Column(Modifier.fillMaxWidth().padding(16.dp).verticalScroll(rememberScrollState())) {
            Text(stringResource(R.string.conflict), style = MaterialTheme.typography.headlineSmall)
            write.payload.forEach { (field, mine) ->
                Text(fieldLabel(field))
                Text(stringResource(R.string.mine, mine ?: stringResource(R.string.not_set)))
                Text(stringResource(R.string.theirs, theirs[field] ?: stringResource(R.string.not_set)))
                Row(Modifier.fillMaxWidth().heightIn(min = 48.dp).toggleable(field in selected,
                    role = Role.Checkbox, onValueChange = { selected = if (it) selected + field else selected - field })) {
                    Checkbox(field in selected, null)
                    Text(stringResource(R.string.keep_field, fieldLabel(field)))
                }
            }
            Button(onClick = { resolve(selected) }) { Text(stringResource(R.string.keep_mine)) }
            TextButton(onClick = { resolve(emptySet()) }) { Text(stringResource(R.string.take_theirs)) }
        }
    }
}
