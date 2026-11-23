package com.code101.tasks.data.repository

import com.code101.tasks.data.local.CacheDao
import com.code101.tasks.data.local.OutboxRow
import com.code101.tasks.data.local.TaskRow
import com.code101.tasks.data.local.toDomain
import com.code101.tasks.data.local.toRow
import com.code101.tasks.data.remote.RemoteDataSource
import com.code101.tasks.data.remote.wireJson
import com.code101.tasks.data.sync.RetryPolicy
import com.code101.tasks.data.sync.SyncScheduler
import com.code101.tasks.domain.model.ApiFailure
import com.code101.tasks.domain.model.Project
import com.code101.tasks.domain.model.TaskItem
import com.code101.tasks.domain.model.Team
import com.code101.tasks.domain.repository.TasksRepository
import java.io.IOException
import java.util.UUID
import javax.inject.Inject
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive
import kotlinx.serialization.json.put

class OfflineFirstTasksRepository @Inject constructor(
    private val dao: CacheDao,
    private val remote: RemoteDataSource,
    private val scheduler: SyncScheduler,
) : TasksRepository {
    private val syncMutex = Mutex()

    override val pendingCount: Flow<Int> = dao.observePendingCount()

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
        val id = UUID.randomUUID().toString()
        val now = System.currentTimeMillis()
        dao.queueCreate(
            task = TaskRow(id, projectId, title, "todo", 0, "pending"),
            outbox = OutboxRow(
                id = id,
                kind = "create_task",
                entityId = id,
                parentId = projectId,
                payload = buildJsonObject { put("title", title) }.toString(),
                baseVersion = null,
                state = "pending",
                attempts = 0,
                nextAttemptAt = now,
                problem = null,
                createdAt = now,
            ),
        )
        scheduler.syncSoon()
    }

    override suspend fun sync() {
        syncMutex.withLock {
            while (true) {
                val row = dao.nextDue(System.currentTimeMillis()) ?: break
                try {
                    send(row)
                } catch (e: ApiFailure) {
                    if (RetryPolicy.isRetryable(e.problem.status)) {
                        retryLater(row, e.problem.retryAfterMillis)
                        break
                    }
                    dao.park(row.id, row.entityId, "${e.problem.status} ${e.problem.title}")
                } catch (e: IOException) {
                    retryLater(row, 0)
                    break
                }
            }
        }
    }

    private suspend fun send(row: OutboxRow) {
        when (row.kind) {
            "create_task" -> {
                val title = wireJson.parseToJsonElement(row.payload).jsonObject["title"]?.jsonPrimitive?.content.orEmpty()
                val created = remote.createTask(row.parentId, title, row.id)
                dao.completeCreate(row.id, row.entityId, created.toRow())
            }
            else -> dao.park(row.id, row.entityId, "unknown kind")
        }
    }

    private suspend fun retryLater(row: OutboxRow, retryAfterMillis: Long) {
        val attempts = row.attempts + 1
        val next = System.currentTimeMillis() + RetryPolicy.delayMillis(attempts, retryAfterMillis)
        dao.scheduleRetry(row.id, attempts, next)
    }
}
