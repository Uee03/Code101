package com.code101.tasks.di

import android.content.Context
import androidx.room.Room
import com.code101.tasks.data.local.CacheDao
import com.code101.tasks.data.local.MIGRATION_1_2
import com.code101.tasks.data.local.TasksDatabase
import dagger.Module
import dagger.Provides
import dagger.hilt.InstallIn
import dagger.hilt.android.qualifiers.ApplicationContext
import dagger.hilt.components.SingletonComponent
import javax.inject.Singleton

@Module
@InstallIn(SingletonComponent::class)
object DatabaseModule {
    @Provides
    @Singleton
    fun database(@ApplicationContext context: Context): TasksDatabase =
        Room.databaseBuilder(context, TasksDatabase::class.java, "tasks.db")
            .addMigrations(MIGRATION_1_2)
            .build()

    @Provides
    fun cacheDao(database: TasksDatabase): CacheDao = database.cacheDao()
}
