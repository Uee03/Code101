package com.code101.tasks.data.repository

import com.code101.tasks.BuildConfig
import com.code101.tasks.data.local.CacheStore
import com.code101.tasks.data.remote.*
import com.code101.tasks.domain.model.*
import com.code101.tasks.domain.repository.TasksRepository
import kotlinx.coroutines.*
import kotlinx.coroutines.flow.*
import com.code101.tasks.domain.repository.Session
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import java.io.IOException
import java.time.Instant
import java.time.LocalDate
import java.util.UUID
import javax.inject.Inject
import javax.inject.Singleton
import kotlin.math.min
import kotlin.random.Random

@Singleton
class TasksRepositoryImpl @Inject constructor(private val remote: Remote, private val store: CacheStore,
    private val settings: BackendSettings, network: NetworkMonitor, private val session: Session) : TasksRepository {
    override val snapshot = combine(store.snapshot, session.accountId) { cache, id ->
        if (id == null || (cache.me != null && cache.me.id != id)) Snapshot() else cache
    }.stateIn(CoroutineScope(SupervisorJob() + Dispatchers.IO), SharingStarted.Eagerly, Snapshot())
    override val backendKind = settings.kind
    override val baseUrl = settings.url
    override val online = network.online
    private val drain = Mutex()
    private val backendGuard = Mutex()
    private val cursors = mutableMapOf<String, String?>()
    private val queries = mutableMapOf<String, Pair<Set<String>, String>>()
    private fun requireAccount(cache: Snapshot) {
        val id = session.accountId.value ?: throw IOException("Sign in required")
        if (cache.me != null && cache.me.id != id) throw ApiFailure(ApiProblem("account-changed", "", 409))
    }
    private suspend fun current(): Snapshot = store.current().also(::requireAccount)
    private suspend fun change(block: (Snapshot) -> Snapshot) {
        backendGuard.withLock { store.change { cache -> requireAccount(cache); block(cache) } }
    }
    private suspend fun ensureMe() {
        if (current().me == null) {
            val me = remote.me()
            change { it.copy(me = me) }
        }
    }
    override suspend fun teams(q: String) {
        val me = remote.me()
        // Never show a previous account's offline data to a new account.
        if (current().me?.id?.let { it != me.id } == true) {
            throw ApiFailure(ApiProblem("account-changed", "Delete offline data before switching accounts", 409))
        }
        val result = remote.teams(q)
        change { it.copy(teams = if (q.isEmpty()) result else (it.teams + result).distinctBy { t -> t.id }, me = me) }
    }
    override suspend fun projects(teamId: String, archived: Boolean) {
        ensureMe()
        val result = remote.projects(teamId, archived)
        change { it.copy(projects = it.projects.filterNot { p -> p.teamId == teamId && p.archived == archived } + result) }
    }
    override suspend fun tasks(projectId: String, statuses: Set<String>, sort: String, more: Boolean) {
        ensureMe()
        val query = statuses to sort
        val append = more && queries[projectId] == query
        if (append && cursors[projectId] == null) return
        val result = try { remote.tasks(projectId, statuses, sort, if (append) cursors[projectId] else null) }
        catch (failure: ApiFailure) {
            if (append && failure.problem.status == 400) { cursors.remove(projectId); return tasks(projectId, statuses, sort, false) }
            throw failure
        }
        queries[projectId] = query; cursors[projectId] = result.nextCursor
        change { s ->
            val keep = s.tasks.filter { it.syncState != "synced" || it.projectId != projectId || append }
            s.copy(tasks = (keep + result.items.filter { server -> keep.none { it.id == server.id && it.syncState != "synced" } })
                .associateBy { it.id }.values.toList())
        }
    }
    override suspend fun detail(taskId: String) {
        ensureMe()
        if (current().tasks.any { it.id == taskId && it.syncState != "synced" }) return
        val task = remote.task(taskId); val comments = remote.comments(taskId)
        change { s -> s.copy(tasks = s.tasks.filterNot { it.id == taskId } + task,
            comments = s.comments.filter { it.taskId != taskId || it.syncState != "synced" } + comments) }
    }
    private fun fields(draft: TaskDraft) = linkedMapOf("title" to draft.title.trim(), "description" to draft.description,
        "status" to draft.status, "priority" to draft.priority, "assigneeId" to draft.assigneeId?.ifBlank { null },
        "dueDate" to draft.dueDate?.ifBlank { null })
    private fun fields(task: TaskItem) = fields(TaskDraft(task.title, task.description, task.status, task.priority, task.assigneeId, task.dueDate))
    private fun validate(draft: TaskDraft) {
        val errors = mutableListOf<FieldError>()
        if (draft.title.trim().length !in 1..200) errors += FieldError("/title", "title_limit")
        if (draft.description.length > 10000) errors += FieldError("/description", "description_limit")
        if (!draft.dueDate.isNullOrBlank() && runCatching { LocalDate.parse(draft.dueDate) }.isFailure)
            errors += FieldError("/dueDate", "date_format")
        if (!draft.assigneeId.isNullOrBlank() && runCatching { UUID.fromString(draft.assigneeId) }.isFailure)
            errors += FieldError("/assigneeId", "uuid_format")
        if (errors.isNotEmpty()) throw ApiFailure(ApiProblem("validation-error", "", 422, errors))
    }
    override suspend fun save(projectId: String, id: String?, key: String, draft: TaskDraft, original: TaskItem?) {
        ensureMe()
        validate(draft)
        val now = Instant.now().toString()
        change { s ->
            if (s.outbox.any { it.id == key }) return@change s
            val taskId = id ?: key
            val source = original ?: s.tasks.find { it.id == taskId }
            val target = source?.copy(title = draft.title.trim(), description = draft.description, status = draft.status,
                priority = draft.priority, assigneeId = draft.assigneeId?.ifBlank { null }, dueDate = draft.dueDate?.ifBlank { null },
                syncState = "pending", server = source.server ?: source.copy(server = null)) ?: TaskItem(taskId, projectId, draft.title.trim(), draft.description,
                "todo", draft.priority, draft.assigneeId?.ifBlank { null }, draft.dueDate?.ifBlank { null }, null,
                s.me?.id.orEmpty(), 0, now, now, "pending")
            val create = s.outbox.find { it.entityId == taskId && it.kind == "create_task" && ((it.state == "pending" && it.attempts == 0) || it.state == "failed") }
            val payload = if (source == null || create != null) fields(draft).filterKeys { it != "status" }
                else fields(draft).filter { (k, v) -> fields(source)[k] != v }
            if (payload.isEmpty()) return@change s
            val writes = if (create != null) s.outbox.map { if (it.id == create.id) it.copy(payload = payload,
                    id = if (it.state == "failed") key else it.id, state = "pending", attempts = 0, nextAttemptAt = 0, problem = null) else it }
                else s.outbox + PendingWrite(key, (s.outbox.maxOfOrNull { it.seq } ?: 0) + 1,
                    if (source == null) "create_task" else "update_task", taskId, projectId, payload, source?.version)
            s.copy(tasks = s.tasks.filterNot { it.id == taskId } + target, outbox = writes)
        }
    }
    override suspend fun complete(taskId: String) {
        change { s ->
            val task = s.tasks.first { it.id == taskId }
            val write = PendingWrite(UUID.randomUUID().toString(), (s.outbox.maxOfOrNull { it.seq } ?: 0) + 1,
                "complete_task", taskId, task.projectId, emptyMap(), task.version)
            s.copy(tasks = s.tasks.map { if (it.id == taskId) it.copy(status = "done", completedAt = Instant.now().toString(), syncState = "pending", server = it.server ?: it.copy(server = null)) else it },
                outbox = s.outbox + write)
        }
    }
    override suspend fun comment(taskId: String, body: String, key: String) {
        ensureMe()
        if (body.trim().length !in 1..2000) throw ApiFailure(ApiProblem("validation-error", "", 422,
            listOf(FieldError("/body", "comment_limit"))))
        change { s ->
            if (s.outbox.any { it.id == key }) return@change s
            val me = s.me ?: throw IOException("Account not loaded")
            s.copy(comments = s.comments + Comment(key, taskId, me.id, me.name, body.trim(), Instant.now().toString(), "pending"),
                outbox = s.outbox + PendingWrite(key, (s.outbox.maxOfOrNull { it.seq } ?: 0) + 1,
                    "create_comment", key, taskId, mapOf("body" to body.trim()), null))
        }
    }
    override suspend fun deleteComment(id: String) {
        remote.deleteComment(id)
        change { it.copy(comments = it.comments.filterNot { c -> c.id == id }) }
    }
    override suspend fun connection(): String {
        val up = remote.health(); val me = remote.me()
        if (current().me?.id?.let { it != me.id } == true)
            throw ApiFailure(ApiProblem("account-changed", "", 409))
        change { it.copy(me = me) }
        return if (up) me.name else throw IOException("Database unavailable")
    }
    override suspend fun backend(kind: Backend, custom: String) = drain.withLock {
        backendGuard.withLock {
            check(current().outbox.isEmpty())
            settings.set(if (kind == Backend.Custom) custom else BuildConfig.API_BASE_URL, kind)
            store.change { Snapshot() }; cursors.clear(); queries.clear()
        }
    }
    override suspend fun sync() = drain.withLock {
        change { s -> s.copy(outbox = s.outbox.map { if (it.state == "in_flight") it.copy(state = "pending", attempts = maxOf(1, it.attempts)) else it }) }
        while (true) {
            val rows = current().outbox.sortedBy { it.seq }
            val write = rows.firstOrNull { w -> w.state == "pending" && w.nextAttemptAt <= System.currentTimeMillis() &&
                rows.none { it.seq < w.seq && (it.entityId == w.entityId || it.entityId == w.parentId) } } ?: break
            change { s -> s.copy(outbox = s.outbox.map { if (it.id == write.id) it.copy(state = "in_flight", attempts = maxOf(1, it.attempts)) else it }) }
            try {
                when (write.kind) {
                    "create_task", "update_task", "complete_task" -> {
                        val task = when (write.kind) {
                            "create_task" -> remote.create(write)
                            "update_task" -> remote.edit(write)
                            else -> remote.complete(write)
                        }
                        change { s ->
                            val rest = s.outbox.filterNot { it.id == write.id }.map {
                                it.copy(entityId = if (it.entityId == write.entityId) task.id else it.entityId,
                                    parentId = if (it.parentId == write.entityId) task.id else it.parentId,
                                    baseVersion = if (it.entityId == write.entityId) task.version else it.baseVersion)
                            }
                            val dirty = rest.any { it.entityId == task.id }
                            val local = s.tasks.find { it.id == write.entityId }
                            val result = if (dirty && local != null) local.copy(id = task.id, version = task.version) else task
                            s.copy(tasks = s.tasks.filterNot { it.id == write.entityId } + result,
                                comments = s.comments.map { if (it.taskId == write.entityId) it.copy(taskId = task.id) else it }, outbox = rest)
                        }
                    }
                    "create_comment" -> {
                        val comment = remote.comment(write)
                        change { s -> s.copy(comments = s.comments.filterNot { it.id == write.entityId } + comment,
                            outbox = s.outbox.filterNot { it.id == write.id }) }
                    }
                }
            } catch (failure: Exception) {
                val problem = (failure as? ApiFailure)?.problem
                if (problem?.status == 412) {
                    val server = runCatching { remote.task(write.entityId) }.getOrNull()
                    change { s -> s.copy(tasks = s.tasks.map { if (it.id == write.entityId) it.copy(syncState = "conflict", server = server) else it },
                        outbox = s.outbox.map { if (it.id == write.id) it.copy(state = "conflict", problem = problem) else it }) }
                } else {
                    val retry = failure is IOException || problem?.status in listOf(408, 425, 429) || (problem?.status ?: 0) >= 500
                    val delay = min(3600000L, 1000L * (1L shl min(write.attempts, 12))) + Random.nextLong(1000L)
                    change { s -> s.copy(outbox = s.outbox.map { if (it.id == write.id) it.copy(
                        state = if (retry) "pending" else "failed", attempts = it.attempts + 1,
                        nextAttemptAt = maxOf(System.currentTimeMillis() + delay, problem?.retryAt ?: 0), problem = problem) else it },
                        tasks = s.tasks.map { if (!retry && it.id == write.entityId) it.copy(syncState = "failed") else it },
                        comments = s.comments.map { if (!retry && it.id == write.entityId) it.copy(syncState = "failed") else it }) }
                }
                if (failure is IOException) break
            }
        }
    }
    override suspend fun retry(id: String) {
        val write = current().outbox.find { it.id == id } ?: return
        if (write.state == "conflict") return
        if ((write.problem?.retryAt ?: 0) > System.currentTimeMillis()) return
        change { s -> s.copy(outbox = s.outbox.map { if (it.id == id) it.copy(state = "pending", nextAttemptAt = 0, problem = null) else it }) }
        sync()
    }
    override suspend fun discard(id: String) {
        change { s ->
            val write = s.outbox.find { it.id == id } ?: return@change s
            val dependent = s.outbox.filter { it.entityId == write.entityId || it.parentId == write.entityId }.map { it.id }.toSet()
            s.copy(outbox = s.outbox.filterNot { it.id in dependent },
                tasks = s.tasks.filterNot { it.id == write.entityId && write.kind == "create_task" }
                    .map { if (it.id == write.entityId) it.server ?: it.copy(syncState = "synced") else it },
                comments = s.comments.filterNot { it.id == write.entityId || (write.kind == "create_task" && it.taskId == write.entityId) })
        }
    }
    override suspend fun resolve(taskId: String, keep: Set<String>) {
        val task = current().tasks.first { it.id == taskId }
        val server = task.server ?: remote.task(taskId)
        change { s ->
            val conflict = s.outbox.first { it.entityId == taskId && it.state == "conflict" }
            val payload = conflict.payload.filterKeys { it in keep }
            val local = if (payload.isEmpty()) server else server.copy(
                title = payload["title"] ?: server.title, description = payload["description"] ?: server.description,
                status = payload["status"] ?: server.status, priority = payload["priority"] ?: server.priority,
                assigneeId = if (payload.containsKey("assigneeId")) payload["assigneeId"] else server.assigneeId,
                dueDate = if (payload.containsKey("dueDate")) payload["dueDate"] else server.dueDate,
                syncState = "pending", server = server)
            s.copy(tasks = s.tasks.filterNot { it.id == taskId } + local,
                outbox = s.outbox.filterNot { it.id == conflict.id } +
                    if (payload.isEmpty()) emptyList() else listOf(conflict.copy(payload = payload,
                        baseVersion = server.version, state = "pending", problem = null, nextAttemptAt = 0)))
        }
        sync()
    }
    override suspend fun clear() { drain.withLock { backendGuard.withLock { store.change { Snapshot() } } } }
}
