package com.code101.tasks.ui.navigation

import kotlinx.serialization.Serializable

@Serializable
data object TeamsRoute

@Serializable
data class ProjectsRoute(val teamId: String)

@Serializable
data class TasksRoute(val projectId: String)
