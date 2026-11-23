package com.code101.tasks.data.local

import androidx.room.Database
import androidx.room.RoomDatabase

@Database(
    entities = [TeamRow::class, ProjectRow::class, TaskRow::class, OutboxRow::class],
    version = 2,
    exportSchema = true,
)
abstract class TasksDatabase : RoomDatabase() {
    abstract fun cacheDao(): CacheDao
}
