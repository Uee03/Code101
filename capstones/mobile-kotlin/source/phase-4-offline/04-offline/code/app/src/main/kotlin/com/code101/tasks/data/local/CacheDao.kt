package com.code101.tasks.data.local

import androidx.room.*
import com.code101.tasks.domain.model.*
import kotlinx.coroutines.flow.Flow
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json

@Dao
abstract class CacheDao {
    @Query("SELECT * FROM teams") abstract suspend fun teams(): List<TeamRow>
    @Query("SELECT * FROM projects") abstract suspend fun projects(): List<ProjectRow>
    @Query("SELECT * FROM tasks ORDER BY created_at DESC, id DESC") abstract suspend fun tasks(): List<TaskRow>
    @Query("SELECT * FROM comments ORDER BY created_at, id") abstract suspend fun comments(): List<CommentRow>
    @Query("SELECT * FROM outbox ORDER BY seq") abstract suspend fun outbox(): List<OutboxRow>
    @Query("SELECT * FROM account LIMIT 1") abstract suspend fun account(): AccountRow?
    @Query("SELECT (SELECT COUNT(*) FROM teams) + (SELECT COUNT(*) FROM projects) + (SELECT COUNT(*) FROM tasks) + (SELECT COUNT(*) FROM comments) + (SELECT COUNT(*) FROM outbox) + (SELECT COUNT(*) FROM account)")
    abstract fun invalidations(): Flow<Int>
    @Insert abstract suspend fun teams(rows: List<TeamRow>)
    @Insert abstract suspend fun projects(rows: List<ProjectRow>)
    @Insert abstract suspend fun tasks(rows: List<TaskRow>)
    @Insert abstract suspend fun comments(rows: List<CommentRow>)
    @Insert abstract suspend fun outbox(rows: List<OutboxRow>)
    @Insert abstract suspend fun account(row: AccountRow)
    @Query("DELETE FROM teams") abstract suspend fun clearTeams()
    @Query("DELETE FROM projects") abstract suspend fun clearProjects()
    @Query("DELETE FROM tasks") abstract suspend fun clearTasks()
    @Query("DELETE FROM comments") abstract suspend fun clearComments()
    @Query("DELETE FROM outbox") abstract suspend fun clearOutbox()
    @Query("DELETE FROM account") abstract suspend fun clearAccount()
    @Transaction
    open suspend fun read() = Snapshot(teams().map { it.domain() }, projects().map { it.domain() },
        tasks().map { it.domain() }, comments().map { it.domain() }, outbox().map { it.domain() },
        account()?.let { Json.decodeFromString<Me>(it.json) })
    @Transaction
    open suspend fun replace(snapshot: Snapshot) {
        clearTeams(); clearProjects(); clearTasks(); clearComments(); clearOutbox(); clearAccount()
        teams(snapshot.teams.map { it.row() }); projects(snapshot.projects.map { it.row() })
        tasks(snapshot.tasks.map { it.row() }); comments(snapshot.comments.map { it.row() })
        outbox(snapshot.outbox.map { it.row() })
        snapshot.me?.let { account(AccountRow(it.id, Json.encodeToString(it))) }
    }
}
