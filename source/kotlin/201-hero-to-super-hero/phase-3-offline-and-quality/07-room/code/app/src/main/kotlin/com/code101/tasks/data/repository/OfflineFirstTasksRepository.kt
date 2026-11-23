package com.code101.tasks.data.repository

import com.code101.tasks.data.local.CacheDao
import com.code101.tasks.data.local.toDomain
import com.code101.tasks.data.local.toRow
import com.code101.tasks.data.remote.RemoteDataSource
import com.code101.tasks.domain.model.Project
import com.code101.tasks.domain.model.TaskItem
import com.code101.tasks.domain.model.Team
import com.code101.tasks.domain.repository.TasksRepository
import java.util.UUID
import javax.inject.Inject
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map

class OfflineFirstTasksRepository @Inject constructor(
    private val dao: CacheDao,
    private val remote: RemoteDataSource,
) : TasksRepository {
    override fun teams(query: String): Flow<List<Team>> =
        dao.observeTeams().map { rows ->
            rows.filter { it.name.contains(query, ignoreCase = true) }.map { it.toDomain() }
        }

    override fun projects(teamId: String): Flow<List<Project>> =
        dao.observeProjects(teamId).map { rows -> rows.map { it.toDomain() } }

    override fun tasks(projectId: String): Flow<List<TaskItem>> =
        dao.observeTasks(projectId).map { rows -> rows.map { it.toDomain() } }

    override suspend fun refreshTeams() {
        dao.replaceTeams(remote.teams().map { it.toRow() })
    }

    override suspend fun refreshProjects(teamId: String) {
        dao.replaceProjects(teamId, remote.projects(teamId).map { it.toRow() })
    }

    override suspend fun refreshTasks(projectId: String) {
        dao.replaceTasks(projectId, remote.tasks(projectId).map { it.toRow() })
    }

    override suspend fun addTask(projectId: String, title: String) {
        val created = remote.createTask(projectId, title, UUID.randomUUID().toString())
        dao.upsertTasks(listOf(created.toRow()))
    }
}
