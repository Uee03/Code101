package com.code101.tasks.ui.navigation

import kotlinx.serialization.Serializable

@Serializable data object SessionCheckRoute
@Serializable data object LoginRoute
@Serializable data object TeamsRoute
@Serializable data class ProjectsRoute(val teamId: String)
@Serializable data class TasksRoute(val projectId: String)
@Serializable data class TaskDetailRoute(val taskId: String)
@Serializable data class CreateTaskRoute(val projectId: String)
@Serializable data class EditTaskRoute(val taskId: String)
@Serializable data object SettingsRoute
@Serializable data object SyncRoute
