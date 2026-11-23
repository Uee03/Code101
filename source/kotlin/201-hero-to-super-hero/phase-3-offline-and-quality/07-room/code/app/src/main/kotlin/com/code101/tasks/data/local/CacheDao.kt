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

    @Query("DELETE FROM tasks WHERE project_id = :projectId")
    abstract suspend fun clearTasks(projectId: String)

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
        clearTasks(projectId)
        upsertTasks(rows)
    }
}
