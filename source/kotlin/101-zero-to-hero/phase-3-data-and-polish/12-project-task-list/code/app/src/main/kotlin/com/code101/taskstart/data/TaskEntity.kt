package com.code101.taskstart.data

import androidx.room.Entity
import androidx.room.PrimaryKey
import com.code101.taskstart.model.Task

@Entity(tableName = "tasks")
data class TaskEntity(
    @PrimaryKey(autoGenerate = true) val id: Int = 0,
    val title: String,
    val done: Boolean = false,
)

fun TaskEntity.toTask() = Task(id = id, title = title, done = done)
