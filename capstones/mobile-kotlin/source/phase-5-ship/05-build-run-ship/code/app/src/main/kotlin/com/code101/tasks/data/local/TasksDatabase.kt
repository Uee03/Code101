package com.code101.tasks.data.local

import androidx.room.Database
import androidx.room.RoomDatabase

@Database(entities = [TeamRow::class, ProjectRow::class, TaskRow::class, CommentRow::class,
    OutboxRow::class, AccountRow::class], version = 1, exportSchema = true)
abstract class TasksDatabase : RoomDatabase() {
    abstract fun cache(): CacheDao
}
