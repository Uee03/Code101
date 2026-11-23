package com.code101.taskstart.ui

import androidx.compose.runtime.Composable
import androidx.compose.runtime.mutableStateListOf
import androidx.compose.runtime.remember
import androidx.navigation.NavType
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import androidx.navigation.navArgument
import com.code101.taskstart.model.Task

@Composable
fun TasksApp() {
    val navController = rememberNavController()
    val tasks = remember {
        mutableStateListOf(
            Task(1, "Buy milk"),
            Task(2, "Call dentist"),
            Task(3, "Pay rent", done = true),
        )
    }

    NavHost(navController = navController, startDestination = "home") {
        composable("home") {
            HomeScreen(
                tasks = tasks,
                onAdd = { title ->
                    val nextId = (tasks.maxOfOrNull { it.id } ?: 0) + 1
                    tasks.add(Task(nextId, title))
                },
                onToggle = { id ->
                    val index = tasks.indexOfFirst { it.id == id }
                    if (index >= 0) {
                        tasks[index] = tasks[index].copy(done = !tasks[index].done)
                    }
                },
                onOpen = { id -> navController.navigate("detail/$id") },
            )
        }
        composable(
            route = "detail/{taskId}",
            arguments = listOf(navArgument("taskId") { type = NavType.IntType }),
        ) { entry ->
            val taskId = entry.arguments?.getInt("taskId")
            DetailScreen(
                task = tasks.firstOrNull { it.id == taskId },
                onBack = { navController.popBackStack() },
                onDelete = {
                    tasks.removeAll { it.id == taskId }
                    navController.popBackStack()
                },
            )
        }
    }
}
