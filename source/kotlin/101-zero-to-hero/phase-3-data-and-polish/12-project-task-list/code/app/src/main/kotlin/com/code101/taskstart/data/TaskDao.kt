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

    @Query("UPDATE tasks SET title = :title WHERE id = :id")
    suspend fun rename(id: Int, title: String)

    @Query("DELETE FROM tasks WHERE id = :id")
    suspend fun delete(id: Int)
}
