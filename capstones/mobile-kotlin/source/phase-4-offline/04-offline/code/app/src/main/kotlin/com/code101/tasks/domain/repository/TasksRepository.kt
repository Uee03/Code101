package com.code101.tasks.domain.repository

import com.code101.tasks.domain.model.*
import kotlinx.coroutines.flow.StateFlow

interface TasksRepository {
    val snapshot: StateFlow<Snapshot>
    val backendKind: StateFlow<Backend>
    val baseUrl: StateFlow<String>
    val online: StateFlow<Boolean>
    suspend fun teams(q: String = "")
    suspend fun projects(teamId: String, archived: Boolean)
    suspend fun tasks(projectId: String, statuses: Set<String>, sort: String, more: Boolean = false)
    suspend fun detail(taskId: String)
    suspend fun save(projectId: String, id: String?, key: String, draft: TaskDraft, original: TaskItem?)
    suspend fun complete(taskId: String)
    suspend fun comment(taskId: String, body: String, key: String)
    suspend fun deleteComment(id: String)
    suspend fun connection(): String
    suspend fun backend(kind: Backend, custom: String)
    suspend fun hasPending(): Boolean
    suspend fun sync()
    suspend fun retry(id: String)
    suspend fun discard(id: String)
    suspend fun resolve(taskId: String, keep: Set<String>)
    suspend fun clear()
}
