package com.code101.tasks.data.remote

import com.code101.tasks.domain.model.*
import com.code101.tasks.generated.api.*
import com.code101.tasks.generated.model.TaskCreate
import com.code101.tasks.generated.model.CommentCreate
import com.code101.tasks.generated.model.TaskStatus
import com.code101.tasks.generated.model.TaskPriority
import kotlinx.serialization.json.*
import retrofit2.Retrofit
import retrofit2.Response
import retrofit2.http.*
import java.time.LocalDate
import java.util.UUID
import javax.inject.Inject
import javax.inject.Singleton

// A narrow adapter is needed because generated nullable fields lose absent-versus-null.
interface MergePatchApi {
    @Headers("Content-Type: application/merge-patch+json")
    @PATCH("v1/tasks/{id}")
    suspend fun update(@Path("id") id: String, @Header("If-Match") etag: String,
                       @Body patch: JsonObject): Response<com.code101.tasks.generated.model.Task>
}
@Singleton
class Remote @Inject constructor(retrofit: Retrofit) {
    private val teamsApi = retrofit.create(TeamsApi::class.java)
    private val projectsApi = retrofit.create(ProjectsApi::class.java)
    private val tasksApi = retrofit.create(TasksApi::class.java)
    private val commentsApi = retrofit.create(CommentsApi::class.java)
    private val platformApi = retrofit.create(PlatformApi::class.java)
    private val patchApi = retrofit.create(MergePatchApi::class.java)
    suspend fun teams(q: String): List<Team> {
        val all = mutableListOf<Team>(); var cursor: String? = null
        do {
            val page = teamsApi.listTeams(cursor = cursor, q = q).required()
            all += page.items.map { Team(it.id.toString(), it.name, it.description, it.memberCount, it.version, it.updatedAt.toString()) }
            cursor = page.page.nextCursor
        } while (cursor != null)
        return all
    }
    suspend fun projects(id: String, archived: Boolean): List<Project> {
        val all = mutableListOf<Project>(); var cursor: String? = null
        do {
            val page = projectsApi.listProjects(UUID.fromString(id), cursor = cursor, archived = archived).required()
            all += page.items.map { Project(it.id.toString(), it.teamId.toString(), it.key, it.name, it.description, it.archived, it.version) }
            cursor = page.page.nextCursor
        } while (cursor != null)
        return all
    }
    suspend fun tasks(id: String, statuses: Set<String>, sort: String, cursor: String?): Page<TaskItem> {
        val page = tasksApi.listTasks(UUID.fromString(id), limit = 25, cursor = cursor,
            sort = TasksApi.SortListTasks.entries.first { it.value == sort },
            status = statuses.takeIf { it.isNotEmpty() }?.map { s -> TaskStatus.entries.first { it.value == s } }).required()
        return Page(page.items.map { it.domain() }, page.page.nextCursor)
    }
    suspend fun task(id: String) = tasksApi.getTask(UUID.fromString(id)).required().domain()
    suspend fun comments(id: String): List<Comment> {
        val all = mutableListOf<Comment>(); var cursor: String? = null
        do {
            val page = commentsApi.listComments(UUID.fromString(id), cursor = cursor).required()
            all += page.items.map { it.domain() }; cursor = page.page.nextCursor
        } while (cursor != null)
        return all
    }
    suspend fun me(): Me {
        val me = platformApi.getMe().required()
        return Me(me.id.toString(), me.displayName, me.roles.map { it.value }, me.scopes)
    }
    suspend fun health(): Boolean = platformApi.getHealth().required().database?.value == "up"
    suspend fun create(write: PendingWrite): TaskItem {
        val p = write.payload
        return tasksApi.createTask(UUID.fromString(write.parentId), TaskCreate(
            title = p.getValue("title")!!, description = p["description"].orEmpty(),
            priority = TaskPriority.entries.first { it.value == p["priority"] },
            assigneeId = p["assigneeId"]?.let(UUID::fromString), dueDate = p["dueDate"]?.let(LocalDate::parse)), write.id).required().domain()
    }
    suspend fun edit(write: PendingWrite): TaskItem {
        val patch = JsonObject(write.payload.mapValues { (_, value) -> value?.let(::JsonPrimitive) ?: JsonNull })
        return patchApi.update(write.entityId, "\"${write.baseVersion}\"", patch).required().domain()
    }
    suspend fun complete(write: PendingWrite) = tasksApi.completeTask("\"${write.baseVersion}\"", UUID.fromString(write.entityId)).required().domain()
    suspend fun comment(write: PendingWrite) = commentsApi.createComment(UUID.fromString(write.parentId),
        CommentCreate(write.payload.getValue("body")!!), write.id).required().domain()
    suspend fun deleteComment(id: String) {
        val response = commentsApi.deleteComment(UUID.fromString(id))
        if (!response.isSuccessful) throw ApiFailure(ProblemParser.parse(response))
    }
}
private fun com.code101.tasks.generated.model.Task.domain() = TaskItem(id.toString(), projectId.toString(),
    title, description, status.value, priority.value, assigneeId?.toString(), dueDate?.toString(),
    completedAt?.toString(), createdBy.toString(), version, createdAt.toString(), updatedAt.toString())
private fun com.code101.tasks.generated.model.Comment.domain() = Comment(id.toString(), taskId.toString(),
    author.id.toString(), author.displayName, body, createdAt.toString())
