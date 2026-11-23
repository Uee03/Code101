package com.code101.taskstart.data

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.Query
import kotlinx.coroutines.flow.Flow

@Dao
interface TaskDao {
    @Query("SELECT * FROM tasks ORDER BY id")
    fun observeAll(): Flow<List<TaskEntity>>

    @Insert
    suspend fun insert(task: TaskEntity)

    @Insert
    suspend fun insertAll(tasks: List<TaskEntity>)

    @Query("UPDATE tasks SET done = NOT done WHERE id = :id")
    suspend fun toggle(id: Int)

    @Query("DELETE FROM tasks WHERE id = :id")
    suspend fun delete(id: Int)

    @Query("DELETE FROM tasks WHERE done = 1")
    suspend fun deleteDone()

    @Query("SELECT COUNT(*) FROM tasks WHERE done = 0")
    fun observeOpenCount(): Flow<Int>
}
