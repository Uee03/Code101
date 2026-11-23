package com.code101.tasks.ui.navigation

import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.platform.LocalContext
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewmodel.compose.viewModel
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import androidx.navigation.toRoute
import com.code101.tasks.TasksApplication
import com.code101.tasks.ui.projects.ProjectsScreen
import com.code101.tasks.ui.projects.ProjectsViewModel
import com.code101.tasks.ui.tasks.TasksScreen
import com.code101.tasks.ui.tasks.TasksViewModel
import com.code101.tasks.ui.teams.TeamsScreen
import com.code101.tasks.ui.teams.TeamsViewModel

@Composable
fun AppGraph() {
    val navController = rememberNavController()
    val application = LocalContext.current.applicationContext as TasksApplication
    val repository = application.repository

    NavHost(navController = navController, startDestination = TeamsRoute) {
        composable<TeamsRoute> {
            val viewModel: TeamsViewModel = viewModel(factory = TeamsViewModel.factory(repository))
            val state by viewModel.state.collectAsStateWithLifecycle()
            TeamsScreen(
                state = state,
                onRetry = viewModel::load,
                onOpenTeam = { teamId -> navController.navigate(ProjectsRoute(teamId)) },
            )
        }
        composable<ProjectsRoute> { entry ->
            val route = entry.toRoute<ProjectsRoute>()
            val viewModel: ProjectsViewModel =
                viewModel(factory = ProjectsViewModel.factory(repository, route.teamId))
            val state by viewModel.state.collectAsStateWithLifecycle()
            ProjectsScreen(
                state = state,
                onRetry = viewModel::load,
                onOpenProject = { projectId -> navController.navigate(TasksRoute(projectId)) },
                onBack = { navController.popBackStack() },
            )
        }
        composable<TasksRoute> { entry ->
            val route = entry.toRoute<TasksRoute>()
            val viewModel: TasksViewModel =
                viewModel(factory = TasksViewModel.factory(repository, route.projectId))
            val state by viewModel.state.collectAsStateWithLifecycle()
            TasksScreen(
                state = state,
                onRetry = viewModel::load,
                onAdd = viewModel::addTask,
                onBack = { navController.popBackStack() },
            )
        }
    }
}
