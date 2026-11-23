package com.code101.tasks.data.repository

import com.code101.tasks.domain.model.Project
import com.code101.tasks.domain.model.TaskItem
import com.code101.tasks.domain.model.Team
import com.code101.tasks.domain.repository.TasksRepository
import java.util.UUID
import javax.inject.Inject
import kotlinx.coroutines.delay

class FakeTasksRepository @Inject constructor() : TasksRepository {
    private val sampleTeams = listOf(
        Team("t1", "Platform Team", "Services and tooling", 4),
        Team("t2", "Mobile Team", "Android and iOS apps", 3),
    )
    private val sampleProjects = listOf(
        Project("p1", "t1", "PLAT", "API gateway"),
        Project("p2", "t2", "MOB", "Tasks app"),
    )
    private val sampleTasks = mutableListOf(
        TaskItem("k1", "p2", "Draw the login screen", "todo", 1),
        TaskItem("k2", "p2", "Wire the Retrofit client", "in_progress", 1),
        TaskItem("k3", "p1", "Write the OpenAPI file", "done", 3),
    )

    override suspend fun teams(): List<Team> {
        delay(300)
        return sampleTeams
    }

    override suspend fun projects(teamId: String): List<Project> {
        delay(300)
        return sampleProjects.filter { it.teamId == teamId }
    }

    override suspend fun tasks(projectId: String): List<TaskItem> {
        delay(300)
        return sampleTasks.filter { it.projectId == projectId }
    }

    override suspend fun addTask(projectId: String, title: String): TaskItem {
        delay(300)
        val task = TaskItem(UUID.randomUUID().toString(), projectId, title, "todo", 1)
        sampleTasks.add(task)
        return task
    }
}
