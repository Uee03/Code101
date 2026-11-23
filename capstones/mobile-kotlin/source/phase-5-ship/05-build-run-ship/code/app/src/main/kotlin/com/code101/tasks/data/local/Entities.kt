package com.code101.tasks.data.local

import androidx.room.*
import com.code101.tasks.domain.model.*
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json

@Entity(tableName = "teams")
data class TeamRow(@PrimaryKey val id: String, val name: String, val description: String,
    @ColumnInfo(name = "member_count") val memberCount: Int, val version: Int,
    @ColumnInfo(name = "updated_at") val updatedAt: String)
@Entity(tableName = "projects", indices = [Index("team_id")])
data class ProjectRow(@PrimaryKey val id: String, @ColumnInfo(name = "team_id") val teamId: String,
    val key: String, val name: String, val description: String, val archived: Boolean, val version: Int)
@Entity(tableName = "tasks", indices = [Index(value = ["project_id", "created_at", "id"],
    orders = [Index.Order.ASC, Index.Order.DESC, Index.Order.DESC])])
data class TaskRow(@PrimaryKey val id: String, @ColumnInfo(name = "project_id") val projectId: String,
    val title: String, val description: String, val status: String, val priority: String,
    @ColumnInfo(name = "assignee_id") val assigneeId: String?, @ColumnInfo(name = "due_date") val dueDate: String?,
    @ColumnInfo(name = "completed_at") val completedAt: String?, @ColumnInfo(name = "created_by") val createdBy: String,
    val version: Int, @ColumnInfo(name = "created_at") val createdAt: String,
    @ColumnInfo(name = "updated_at") val updatedAt: String, @ColumnInfo(name = "sync_state") val syncState: String,
    @ColumnInfo(name = "server_json") val serverJson: String?)
@Entity(tableName = "comments", indices = [Index(value = ["task_id", "created_at"])])
data class CommentRow(@PrimaryKey val id: String, @ColumnInfo(name = "task_id") val taskId: String,
    @ColumnInfo(name = "author_id") val authorId: String, @ColumnInfo(name = "author_name") val authorName: String,
    val body: String, @ColumnInfo(name = "created_at") val createdAt: String, @ColumnInfo(name = "sync_state") val syncState: String)
@Entity(tableName = "outbox", indices = [Index(value = ["id"], unique = true),
    Index(value = ["state", "next_attempt_at"]), Index(value = ["entity_id", "seq"])])
data class OutboxRow(@PrimaryKey(autoGenerate = true) val seq: Long = 0, val id: String,
    val kind: String, @ColumnInfo(name = "entity_id") val entityId: String,
    @ColumnInfo(name = "parent_id") val parentId: String, val payload: String,
    @ColumnInfo(name = "base_version") val baseVersion: Int?, val state: String, val attempts: Int,
    @ColumnInfo(name = "next_attempt_at") val nextAttemptAt: Long, val problem: String?,
    @ColumnInfo(name = "created_at") val createdAt: Long)
@Entity(tableName = "account")
data class AccountRow(@PrimaryKey val id: String, val json: String)

fun Team.row() = TeamRow(id, name, description, memberCount, version, updatedAt)
fun TeamRow.domain() = Team(id, name, description, memberCount, version, updatedAt)
fun Project.row() = ProjectRow(id, teamId, key, name, description, archived, version)
fun ProjectRow.domain() = Project(id, teamId, key, name, description, archived, version)
fun TaskItem.row() = TaskRow(id, projectId, title, description, status, priority, assigneeId, dueDate,
    completedAt, createdBy, version, createdAt, updatedAt, syncState, server?.let { Json.encodeToString(it) })
fun TaskRow.domain() = TaskItem(id, projectId, title, description, status, priority, assigneeId, dueDate,
    completedAt, createdBy, version, createdAt, updatedAt, syncState, serverJson?.let { Json.decodeFromString<TaskItem>(it) })
fun Comment.row() = CommentRow(id, taskId, authorId, authorName, body, createdAt, syncState)
fun CommentRow.domain() = Comment(id, taskId, authorId, authorName, body, createdAt, syncState)
fun PendingWrite.row() = OutboxRow(seq, id, kind, entityId, parentId, Json.encodeToString(payload),
    baseVersion, state, attempts, nextAttemptAt, problem?.let { Json.encodeToString(it) }, createdAt)
fun OutboxRow.domain() = PendingWrite(id, seq, kind, entityId, parentId, Json.decodeFromString(payload),
    baseVersion, state, attempts, nextAttemptAt, problem?.let { Json.decodeFromString<ApiProblem>(it) }, createdAt)
