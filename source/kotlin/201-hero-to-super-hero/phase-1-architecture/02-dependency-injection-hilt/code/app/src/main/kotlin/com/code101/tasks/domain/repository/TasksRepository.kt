package com.code101.tasks.domain.repository

import com.code101.tasks.domain.model.Project
import com.code101.tasks.domain.model.TaskItem
import com.code101.tasks.domain.model.Team

interface TasksRepository {
    suspend fun teams(): List<Team>

    suspend fun projects(teamId: String): List<Project>

    suspend fun tasks(projectId: String): List<TaskItem>

    suspend fun addTask(projectId: String, title: String): TaskItem
}
