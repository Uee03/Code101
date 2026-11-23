package com.code101.tasks.data.local

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import androidx.room.Transaction
import kotlinx.coroutines.flow.Flow

@Dao
abstract class CacheDao {
    @Query("SELECT * FROM teams ORDER BY name")
    abstract fun observeTeams(): Flow<List<TeamRow>>

    @Query("SELECT * FROM projects WHERE team_id = :teamId ORDER BY name")
    abstract fun observeProjects(teamId: String): Flow<List<ProjectRow>>

    @Query("SELECT * FROM tasks WHERE project_id = :projectId ORDER BY title")
    abstract fun observeTasks(projectId: String): Flow<List<TaskRow>>

    @Query("SELECT COUNT(*) FROM outbox WHERE state = 'pending'")
    abstract fun observePendingCount(): Flow<Int>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    abstract suspend fun upsertTeams(rows: List<TeamRow>)

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    abstract suspend fun upsertProjects(rows: List<ProjectRow>)

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    abstract suspend fun upsertTasks(rows: List<TaskRow>)

    @Query("DELETE FROM teams")
    abstract suspend fun clearTeams()

    @Query("DELETE FROM projects WHERE team_id = :teamId")
    abstract suspend fun clearProjects(teamId: String)

    @Query("DELETE FROM tasks WHERE project_id = :projectId AND sync_state = 'synced'")
    abstract suspend fun clearSyncedTasks(projectId: String)

    @Transaction
    open suspend fun replaceTeams(rows: List<TeamRow>) {
        clearTeams()
        upsertTeams(rows)
    }

    @Transaction
    open suspend fun replaceProjects(teamId: String, rows: List<ProjectRow>) {
        clearProjects(teamId)
        upsertProjects(rows)
    }

    @Transaction
    open suspend fun replaceTasks(projectId: String, rows: List<TaskRow>) {
        clearSyncedTasks(projectId)
        upsertTasks(rows)
    }

    @Insert
    abstract suspend fun insertOutbox(row: OutboxRow)

    @Query("SELECT * FROM outbox WHERE state = 'pending' AND next_attempt_at <= :now ORDER BY seq LIMIT 1")
    abstract suspend fun nextDue(now: Long): OutboxRow?

    @Query("DELETE FROM outbox WHERE id = :id")
    abstract suspend fun deleteOutbox(id: String)

    @Query("DELETE FROM tasks WHERE id = :id")
    abstract suspend fun deleteTask(id: String)

    @Query("UPDATE outbox SET attempts = :attempts, next_attempt_at = :nextAttemptAt WHERE id = :id")
    abstract suspend fun scheduleRetry(id: String, attempts: Int, nextAttemptAt: Long)

    @Query("UPDATE outbox SET state = 'failed', problem = :problem WHERE id = :id")
    abstract suspend fun parkOutbox(id: String, problem: String)

    @Query("UPDATE tasks SET sync_state = :state WHERE id = :id")
    abstract suspend fun setTaskSyncState(id: String, state: String)

    @Transaction
    open suspend fun queueCreate(task: TaskRow, outbox: OutboxRow) {
        upsertTasks(listOf(task))
        insertOutbox(outbox)
    }

    @Transaction
    open suspend fun completeCreate(outboxId: String, localId: String, server: TaskRow) {
        deleteTask(localId)
        upsertTasks(listOf(server))
        deleteOutbox(outboxId)
    }

    @Transaction
    open suspend fun park(outboxId: String, taskId: String, problem: String) {
        parkOutbox(outboxId, problem)
        setTaskSyncState(taskId, "failed")
    }
}
