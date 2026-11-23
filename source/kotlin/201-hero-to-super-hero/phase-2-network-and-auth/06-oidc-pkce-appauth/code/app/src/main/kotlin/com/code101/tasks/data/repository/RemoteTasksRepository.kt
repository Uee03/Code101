package com.code101.tasks.data.repository

import com.code101.tasks.data.remote.RemoteDataSource
import com.code101.tasks.domain.model.Project
import com.code101.tasks.domain.model.TaskItem
import com.code101.tasks.domain.model.Team
import com.code101.tasks.domain.repository.TasksRepository
import java.util.UUID
import javax.inject.Inject
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.flow.update

class RemoteTasksRepository @Inject constructor(
    private val remote: RemoteDataSource,
) : TasksRepository {
    private val cachedTeams = MutableStateFlow<List<Team>>(emptyList())
    private val cachedProjects = MutableStateFlow<List<Project>>(emptyList())
    private val cachedTasks = MutableStateFlow<List<TaskItem>>(emptyList())

    override fun teams(query: String): Flow<List<Team>> =
        cachedTeams.map { teams -> teams.filter { it.name.contains(query, ignoreCase = true) } }

    override fun projects(teamId: String): Flow<List<Project>> =
        cachedProjects.map { projects -> projects.filter { it.teamId == teamId } }

    override fun tasks(projectId: String): Flow<List<TaskItem>> =
        cachedTasks.map { tasks -> tasks.filter { it.projectId == projectId } }

    override suspend fun refreshTeams() {
        cachedTeams.value = remote.teams()
    }

    override suspend fun refreshProjects(teamId: String) {
        val fresh = remote.projects(teamId)
        cachedProjects.update { current -> current.filterNot { it.teamId == teamId } + fresh }
    }

    override suspend fun refreshTasks(projectId: String) {
        val fresh = remote.tasks(projectId)
        cachedTasks.update { current -> current.filterNot { it.projectId == projectId } + fresh }
    }

    override suspend fun addTask(projectId: String, title: String) {
        val created = remote.createTask(projectId, title, UUID.randomUUID().toString())
        cachedTasks.update { current -> current + created }
    }
}
