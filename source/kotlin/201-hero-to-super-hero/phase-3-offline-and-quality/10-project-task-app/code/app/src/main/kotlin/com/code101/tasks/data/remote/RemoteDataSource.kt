package com.code101.tasks.data.remote

import com.code101.tasks.domain.model.Profile
import com.code101.tasks.domain.model.Project
import com.code101.tasks.domain.model.TaskItem
import com.code101.tasks.domain.model.Team
import com.code101.tasks.generated.api.PlatformApi
import com.code101.tasks.generated.api.ProjectsApi
import com.code101.tasks.generated.api.TasksApi
import com.code101.tasks.generated.api.TeamsApi
import com.code101.tasks.generated.model.TaskCreate
import java.util.UUID
import javax.inject.Inject
import javax.inject.Singleton
import com.code101.tasks.generated.model.Project as ProjectDto
import com.code101.tasks.generated.model.Task as TaskDto
import com.code101.tasks.generated.model.Team as TeamDto

@Singleton
class RemoteDataSource @Inject constructor(
    private val platformApi: PlatformApi,
    private val teamsApi: TeamsApi,
    private val projectsApi: ProjectsApi,
    private val tasksApi: TasksApi,
) {
    suspend fun health(): String {
        val body = platformApi.getHealth().required()
        return body.database?.value ?: body.status.value
    }

    suspend fun teams(): List<Team> {
        val all = mutableListOf<Team>()
        var cursor: String? = null
        do {
            val page = teamsApi.listTeams(cursor = cursor).required()
            all += page.items.map { it.toDomain() }
            cursor = page.page.nextCursor
        } while (cursor != null)
        return all
    }

    suspend fun projects(teamId: String): List<Project> {
        val all = mutableListOf<Project>()
        var cursor: String? = null
        do {
            val page = projectsApi.listProjects(UUID.fromString(teamId), cursor = cursor).required()
            all += page.items.map { it.toDomain() }
            cursor = page.page.nextCursor
        } while (cursor != null)
        return all
    }

    suspend fun tasks(projectId: String): List<TaskItem> {
        val all = mutableListOf<TaskItem>()
        var cursor: String? = null
        do {
            val page = tasksApi.listTasks(UUID.fromString(projectId), cursor = cursor).required()
            all += page.items.map { it.toDomain() }
            cursor = page.page.nextCursor
        } while (cursor != null)
        return all
    }

    suspend fun createTask(projectId: String, title: String, idempotencyKey: String): TaskItem =
        tasksApi.createTask(
            projectId = UUID.fromString(projectId),
            taskCreate = TaskCreate(title = title),
            idempotencyKey = idempotencyKey,
        ).required().toDomain()

    suspend fun completeTask(taskId: String, version: Int): TaskItem =
        tasksApi.completeTask(
            ifMatch = "\"$version\"",
            taskId = UUID.fromString(taskId),
        ).required().toDomain()

    suspend fun me(): Profile {
        val me = platformApi.getMe().required()
        return Profile(displayName = me.displayName, email = me.email)
    }
}

private fun TeamDto.toDomain() = Team(id.toString(), name, description, memberCount)

private fun ProjectDto.toDomain() = Project(id.toString(), teamId.toString(), key, name)

private fun TaskDto.toDomain() = TaskItem(id.toString(), projectId.toString(), title, status.value, version)
