package com.code101.tasks.data.repository

import com.code101.tasks.di.IoDispatcher
import com.code101.tasks.domain.model.Project
import com.code101.tasks.domain.model.TaskItem
import com.code101.tasks.domain.model.Team
import com.code101.tasks.domain.repository.TasksRepository
import java.io.IOException
import java.util.UUID
import javax.inject.Inject
import kotlinx.coroutines.CoroutineDispatcher
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.withContext

class FakeTasksRepository @Inject constructor(
    @IoDispatcher private val ioDispatcher: CoroutineDispatcher,
) : TasksRepository {
    private val serverTeams = listOf(
        Team("t1", "Platform Team", "Services and tooling", 4),
        Team("t2", "Mobile Team", "Android and iOS apps", 3),
    )
    private val serverProjects = listOf(
        Project("p1", "t1", "PLAT", "API gateway"),
        Project("p2", "t2", "MOB", "Tasks app"),
    )
    private val serverTasks = mutableListOf(
        TaskItem("k1", "p2", "Draw the login screen", "todo", 1),
        TaskItem("k2", "p2", "Wire the Retrofit client", "in_progress", 1),
        TaskItem("k3", "p1", "Write the OpenAPI file", "done", 3),
    )

    private val cachedTeams = MutableStateFlow<List<Team>>(emptyList())
    private val cachedProjects = MutableStateFlow<List<Project>>(emptyList())
    private val cachedTasks = MutableStateFlow<List<TaskItem>>(emptyList())
    private var outageSimulated = false

    override fun teams(query: String): Flow<List<Team>> =
        cachedTeams.map { teams -> teams.filter { it.name.contains(query, ignoreCase = true) } }

    override fun projects(teamId: String): Flow<List<Project>> =
        cachedProjects.map { projects -> projects.filter { it.teamId == teamId } }

    override fun tasks(projectId: String): Flow<List<TaskItem>> =
        cachedTasks.map { tasks -> tasks.filter { it.projectId == projectId } }

    override suspend fun refreshTeams() {
        withContext(ioDispatcher) {
            delay(300)
            cachedTeams.value = serverTeams
        }
    }

    override suspend fun refreshProjects(teamId: String) {
        withContext(ioDispatcher) {
            delay(300)
            if (teamId == "t1" && !outageSimulated) {
                outageSimulated = true
                throw IOException("Simulated outage")
            }
            cachedProjects.update { current ->
                current.filterNot { it.teamId == teamId } + serverProjects.filter { it.teamId == teamId }
            }
        }
    }

    override suspend fun refreshTasks(projectId: String) {
        withContext(ioDispatcher) {
            delay(300)
            cachedTasks.update { current ->
                current.filterNot { it.projectId == projectId } + serverTasks.filter { it.projectId == projectId }
            }
        }
    }

    override suspend fun addTask(projectId: String, title: String) {
        withContext(ioDispatcher) {
            delay(300)
            val task = TaskItem(UUID.randomUUID().toString(), projectId, title, "todo", 1)
            serverTasks.add(task)
            cachedTasks.update { current -> current + task }
        }
    }
}
