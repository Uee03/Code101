package com.code101.taskstart.ui

import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewmodel.compose.viewModel
import androidx.navigation.NavType
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import androidx.navigation.navArgument

@Composable
fun TasksApp(viewModel: TasksViewModel = viewModel()) {
    val navController = rememberNavController()
    val state by viewModel.uiState.collectAsStateWithLifecycle()

    NavHost(navController = navController, startDestination = "home") {
        composable("home") {
            HomeScreen(
                state = state,
                onDraftChange = viewModel::onDraftChange,
                onAdd = viewModel::addTask,
                onToggle = viewModel::toggle,
                onOpen = { id -> navController.navigate("detail/$id") },
            )
        }
        composable(
            route = "detail/{taskId}",
            arguments = listOf(navArgument("taskId") { type = NavType.IntType }),
        ) { entry ->
            val taskId = entry.arguments?.getInt("taskId")
            DetailScreen(
                task = state.tasks.firstOrNull { it.id == taskId },
                onBack = { navController.popBackStack() },
                onDelete = {
                    if (taskId != null) {
                        viewModel.delete(taskId)
                    }
                    navController.popBackStack()
                },
            )
        }
    }
}
