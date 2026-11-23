package com.code101.tasks.ui.tasks

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.material3.*
import androidx.compose.material3.pulltorefresh.PullToRefreshBox
import androidx.compose.runtime.*
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import kotlinx.coroutines.flow.distinctUntilChanged
import com.code101.tasks.R
import com.code101.tasks.ui.TasksViewModel
import com.code101.tasks.ui.components.*

private val statuses = listOf("todo", "in_progress", "blocked", "done", "cancelled")
@OptIn(ExperimentalMaterial3Api::class, ExperimentalLayoutApi::class)
@Composable
fun TasksScreen(id: String, vm: TasksViewModel, open: (String) -> Unit, create: () -> Unit) {
    val state by vm.state.collectAsStateWithLifecycle()
    var filters by rememberSaveable { mutableStateOf(emptyList<String>()) }
    var sort by rememberSaveable { mutableStateOf("-createdAt") }
    val listState = rememberLazyListState()
    LaunchedEffect(id, filters, sort, listState) {
        snapshotFlow { listState.layoutInfo.let { it.totalItemsCount > 2 &&
            (it.visibleItemsInfo.lastOrNull()?.index ?: 0) >= it.totalItemsCount - 2 } }
            .distinctUntilChanged().collect { atEnd -> if (atEnd) vm.load(id, filters.toSet(), sort, true) }
    }
    LaunchedEffect(id, filters, sort) { vm.load(id, filters.toSet(), sort) }
    PullToRefreshBox(isRefreshing = state.busy, onRefresh = { vm.load(id, filters.toSet(), sort) }) {
        PageFrame(R.string.task_list, state, listState) {
            item {
                Action(R.string.new_task, R.drawable.ic_plus, click = create)
                Text(stringResource(R.string.filters))
                FlowRow { statuses.forEach { status ->
                    FilterChip(status in filters, { filters = if (status in filters) filters - status else filters + status },
                        label = { Text(wireLabel(status)) })
                } }
                TextButton(onClick = { filters = emptyList() }) { Text(stringResource(R.string.filters_clear)) }
                FlowRow {
                    listOf("-createdAt" to R.string.sort_newest, "createdAt" to R.string.sort_oldest, "dueDate" to R.string.sort_due).forEach { (key, label) ->
                        FilterChip(sort == key, { sort = key }, label = { Text(stringResource(label)) })
                    }
                }
            }
            val tasks = state.data.tasks.filter { it.projectId == id && (filters.isEmpty() || it.status in filters) }.let { list ->
                when (sort) {
                    "createdAt" -> list.sortedBy { it.createdAt }
                    "dueDate" -> list.sortedWith(compareBy(nullsLast()) { it.dueDate })
                    else -> list.sortedByDescending { it.createdAt }
                }
            }
            if (tasks.isEmpty()) item { Text(stringResource(R.string.empty)) }
            items(tasks, key = { it.id }) { task ->
                TextButton(onClick = { open(task.id) }) { Text(task.title) }
                Text(wireLabel(task.status)); Text(wireLabel(task.syncState))
            }
            item {
                Action(R.string.load_more, R.drawable.ic_refresh_cw, !state.busy) { vm.load(id, filters.toSet(), sort, true) }
            }
        }
    }
}
