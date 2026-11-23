package com.code101.tasks.data.local

import androidx.room.ColumnInfo
import androidx.room.Entity
import androidx.room.Index
import androidx.room.PrimaryKey
import com.code101.tasks.domain.model.Project
import com.code101.tasks.domain.model.TaskItem
import com.code101.tasks.domain.model.Team

@Entity(tableName = "teams")
data class TeamRow(
    @PrimaryKey val id: String,
    val name: String,
    val description: String,
    @ColumnInfo(name = "member_count") val memberCount: Int,
)

@Entity(tableName = "projects", indices = [Index("team_id")])
data class ProjectRow(
    @PrimaryKey val id: String,
    @ColumnInfo(name = "team_id") val teamId: String,
    val key: String,
    val name: String,
)

@Entity(tableName = "tasks", indices = [Index("project_id")])
data class TaskRow(
    @PrimaryKey val id: String,
    @ColumnInfo(name = "project_id") val projectId: String,
    val title: String,
    val status: String,
    val version: Int,
    @ColumnInfo(name = "sync_state") val syncState: String,
)

@Entity(
    tableName = "outbox",
    indices = [
        Index(value = ["id"], unique = true),
        Index(value = ["state", "next_attempt_at"]),
    ],
)
data class OutboxRow(
    @PrimaryKey(autoGenerate = true) val seq: Long = 0,
    val id: String,
    val kind: String,
    @ColumnInfo(name = "entity_id") val entityId: String,
    @ColumnInfo(name = "parent_id") val parentId: String,
    val payload: String,
    @ColumnInfo(name = "base_version") val baseVersion: Int?,
    val state: String,
    val attempts: Int,
    @ColumnInfo(name = "next_attempt_at") val nextAttemptAt: Long,
    val problem: String?,
    @ColumnInfo(name = "created_at") val createdAt: Long,
)

fun Team.toRow() = TeamRow(id, name, description, memberCount)

fun TeamRow.toDomain() = Team(id, name, description, memberCount)

fun Project.toRow() = ProjectRow(id, teamId, key, name)

fun ProjectRow.toDomain() = Project(id, teamId, key, name)

fun TaskItem.toRow() = TaskRow(id, projectId, title, status, version, syncState)

fun TaskRow.toDomain() = TaskItem(id, projectId, title, status, version, syncState)
