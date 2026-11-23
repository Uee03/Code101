package com.code101.tasks.domain.model

import kotlinx.serialization.Serializable

@Serializable
data class Team(val id: String, val name: String, val description: String,
                val memberCount: Int, val version: Int, val updatedAt: String)
@Serializable
data class Project(val id: String, val teamId: String, val key: String, val name: String,
                   val description: String, val archived: Boolean, val version: Int)
@Serializable
data class TaskItem(val id: String, val projectId: String, val title: String,
    val description: String, val status: String, val priority: String,
    val assigneeId: String?, val dueDate: String?, val completedAt: String?,
    val createdBy: String, val version: Int, val createdAt: String, val updatedAt: String,
    val syncState: String = "synced", val server: TaskItem? = null)
@Serializable
data class Comment(val id: String, val taskId: String, val authorId: String,
    val authorName: String, val body: String, val createdAt: String, val syncState: String = "synced")
@Serializable
data class Me(val id: String, val name: String, val roles: List<String>, val scopes: List<String>)
@Serializable
data class FieldError(val pointer: String, val detail: String)
@Serializable
data class ApiProblem(val type: String, val title: String, val status: Int,
    val errors: List<FieldError> = emptyList(), val retryAt: Long = 0, val traceId: String? = null)
class ApiFailure(val problem: ApiProblem) : Exception(problem.title)
@Serializable
data class PendingWrite(val id: String, val seq: Long, val kind: String, val entityId: String,
    val parentId: String, val payload: Map<String, String?>, val baseVersion: Int?,
    val state: String = "pending", val attempts: Int = 0, val nextAttemptAt: Long = 0,
    val problem: ApiProblem? = null, val createdAt: Long = System.currentTimeMillis())
@Serializable
data class Snapshot(val teams: List<Team> = emptyList(), val projects: List<Project> = emptyList(),
    val tasks: List<TaskItem> = emptyList(), val comments: List<Comment> = emptyList(),
    val outbox: List<PendingWrite> = emptyList(), val me: Me? = null)
data class TaskDraft(val title: String = "", val description: String = "", val status: String = "todo",
    val priority: String = "medium", val assigneeId: String? = null, val dueDate: String? = null)
data class Page<T>(val items: List<T>, val nextCursor: String?)
enum class Backend { AspNet, Python, Go, Custom }
