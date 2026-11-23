package com.code101.tasks.domain.repository

import com.code101.tasks.domain.model.Project
import com.code101.tasks.domain.model.TaskItem
import com.code101.tasks.domain.model.Team
import kotlinx.coroutines.flow.Flow

interface TasksRepository {
    val pendingCount: Flow<Int>

    fun teams(query: String): Flow<List<Team>>

    fun projects(teamId: String): Flow<List<Project>>

    fun tasks(projectId: String): Flow<List<TaskItem>>

    suspend fun refreshTeams()

    suspend fun refreshProjects(teamId: String)

    suspend fun refreshTasks(projectId: String)

    suspend fun addTask(projectId: String, title: String)

    suspend fun completeTask(taskId: String)

    suspend fun sync()
}
