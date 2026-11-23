package com.code101.tasks.ui.navigation

import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.hilt.lifecycle.viewmodel.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import com.code101.tasks.ui.account.AccountScreen
import com.code101.tasks.ui.account.AccountViewModel
import com.code101.tasks.ui.components.OfflineBanner
import com.code101.tasks.ui.projects.ProjectsScreen
import com.code101.tasks.ui.projects.ProjectsViewModel
import com.code101.tasks.ui.sync.SyncViewModel
import com.code101.tasks.ui.tasks.TasksScreen
import com.code101.tasks.ui.tasks.TasksViewModel
import com.code101.tasks.ui.teams.ConnectionViewModel
import com.code101.tasks.ui.teams.TeamsScreen
import com.code101.tasks.ui.teams.TeamsViewModel

@Composable
fun AppGraph(onSignOut: () -> Unit) {
    val navController = rememberNavController()
    val syncViewModel: SyncViewModel = hiltViewModel()
    val pendingCount by syncViewModel.pendingCount.collectAsStateWithLifecycle()

    Column(modifier = Modifier.fillMaxSize()) {
        OfflineBanner(pendingCount = pendingCount, onSyncNow = syncViewModel::syncNow)
        NavHost(
            navController = navController,
            startDestination = TeamsRoute,
            modifier = Modifier.weight(1f),
        ) {
            composable<TeamsRoute> {
                val viewModel: TeamsViewModel = hiltViewModel()
                val connectionViewModel: ConnectionViewModel = hiltViewModel()
                val state by viewModel.state.collectAsStateWithLifecycle()
                val connection by connectionViewModel.state.collectAsStateWithLifecycle()
                val searchText by viewModel.searchText.collectAsStateWithLifecycle()
                TeamsScreen(
                    state = state,
                    connection = connection,
                    searchText = searchText,
                    onSearchChange = viewModel::onSearchChange,
                    onCheckConnection = connectionViewModel::check,
                    onOpenAccount = { navController.navigate(AccountRoute) },
                    onRetry = viewModel::refresh,
                    onOpenTeam = { teamId -> navController.navigate(ProjectsRoute(teamId)) },
                )
            }
            composable<ProjectsRoute> {
                val viewModel: ProjectsViewModel = hiltViewModel()
                val state by viewModel.state.collectAsStateWithLifecycle()
                ProjectsScreen(
                    state = state,
                    onRetry = viewModel::refresh,
                    onOpenProject = { projectId -> navController.navigate(TasksRoute(projectId)) },
                    onBack = { navController.popBackStack() },
                )
            }
            composable<TasksRoute> {
                val viewModel: TasksViewModel = hiltViewModel()
                val state by viewModel.state.collectAsStateWithLifecycle()
                val titleError by viewModel.titleError.collectAsStateWithLifecycle()
                TasksScreen(
                    state = state,
                    events = viewModel.events,
                    titleError = titleError,
                    onTitleEdited = viewModel::clearTitleError,
                    onRetry = viewModel::refresh,
                    onAdd = viewModel::addTask,
                    onComplete = viewModel::completeTask,
                    onBack = { navController.popBackStack() },
                )
            }
            composable<AccountRoute> {
                val viewModel: AccountViewModel = hiltViewModel()
                val profile by viewModel.profile.collectAsStateWithLifecycle()
                val pending by viewModel.pendingCount.collectAsStateWithLifecycle()
                val deleted by viewModel.deleted.collectAsStateWithLifecycle()
                AccountScreen(
                    profile = profile,
                    pendingCount = pending,
                    deleted = deleted,
                    onRetry = viewModel::load,
                    onDeleteOfflineData = viewModel::deleteOfflineData,
                    onSignOut = onSignOut,
                    onBack = { navController.popBackStack() },
                )
            }
        }
    }
}
