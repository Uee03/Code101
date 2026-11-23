package com.code101.tasks.ui.navigation

import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.hilt.lifecycle.viewmodel.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.navigation.compose.*
import androidx.navigation.toRoute
import com.code101.tasks.R
import com.code101.tasks.ui.*
import com.code101.tasks.ui.components.*
import com.code101.tasks.ui.projects.ProjectsScreen
import com.code101.tasks.ui.settings.SettingsScreen
import com.code101.tasks.ui.sync.SyncScreen
import com.code101.tasks.ui.taskdetail.TaskDetailScreen
import com.code101.tasks.ui.taskform.TaskFormScreen
import com.code101.tasks.ui.tasks.TasksScreen
import com.code101.tasks.ui.teams.TeamsScreen

@OptIn(ExperimentalLayoutApi::class)
@Composable
fun AppGraph(intended: String?, consumed: () -> Unit, logout: (Boolean) -> Unit) {
    val nav = rememberNavController()
    val sync: SyncViewModel = hiltViewModel()
    val state by sync.state.collectAsStateWithLifecycle()
    val online by sync.online.collectAsStateWithLifecycle()
    LaunchedEffect(intended) {
        val parts = intended?.trim('/')?.split('/').orEmpty()
        when {
            parts.size == 2 && parts[0] == "tasks" -> nav.navigate(TaskDetailRoute(parts[1]))
            parts.size == 3 && parts[0] == "teams" && parts[2] == "projects" -> nav.navigate(ProjectsRoute(parts[1]))
            parts.size == 3 && parts[0] == "projects" && parts[2] == "tasks" -> nav.navigate(TasksRoute(parts[1]))
            parts == listOf("settings") -> nav.navigate(SettingsRoute)
            parts == listOf("settings", "sync") -> nav.navigate(SyncRoute)
        }
        consumed()
    }
    Column(Modifier.fillMaxSize().windowInsetsPadding(WindowInsets.safeDrawing)) {
        OfflineBanner(online, state.data.outbox.size, sync = { sync.sync() }, queue = { nav.navigate(SyncRoute) })
        FlowRow {
            TextButton(onClick = { nav.popBackStack() }) { Text(stringResource(R.string.back)) }
            Action(R.string.teams, R.drawable.ic_team) { nav.navigate(TeamsRoute) }
            Action(R.string.settings, R.drawable.ic_settings) { nav.navigate(SettingsRoute) }
        }
        NavHost(nav, startDestination = TeamsRoute, modifier = Modifier.weight(1f)) {
            composable<SessionCheckRoute> { CircularProgressIndicator() }
            composable<LoginRoute> { Text(stringResource(R.string.login)) }
            composable<TeamsRoute> { TeamsScreen(hiltViewModel()) { nav.navigate(ProjectsRoute(it)) } }
            composable<ProjectsRoute> { entry ->
                ProjectsScreen(entry.toRoute<ProjectsRoute>().teamId, hiltViewModel()) { nav.navigate(TasksRoute(it)) }
            }
            composable<TasksRoute> { entry ->
                val id = entry.toRoute<TasksRoute>().projectId
                TasksScreen(id, hiltViewModel(), open = { nav.navigate(TaskDetailRoute(it)) }, create = { nav.navigate(CreateTaskRoute(id)) })
            }
            composable<TaskDetailRoute> { entry ->
                val id = entry.toRoute<TaskDetailRoute>().taskId
                TaskDetailScreen(id, hiltViewModel()) { nav.navigate(EditTaskRoute(id)) }
            }
            composable<CreateTaskRoute> { entry ->
                TaskFormScreen(entry.toRoute<CreateTaskRoute>().projectId, null, hiltViewModel()) { nav.popBackStack() }
            }
            composable<EditTaskRoute> { entry ->
                TaskFormScreen("", entry.toRoute<EditTaskRoute>().taskId, hiltViewModel()) { nav.popBackStack() }
            }
            composable<SettingsRoute> {
                SettingsScreen(hiltViewModel(), queue = { nav.navigate(SyncRoute) }, logout = logout)
            }
            composable<SyncRoute> { SyncScreen(hiltViewModel()) { nav.navigate(EditTaskRoute(it)) } }
        }
    }
}
