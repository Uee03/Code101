package com.code101.tasks.di

import com.code101.tasks.data.local.CacheStore
import com.code101.tasks.data.local.MemoryStore
import com.code101.tasks.data.repository.TasksRepositoryImpl
import com.code101.tasks.domain.repository.TasksRepository
import dagger.Binds
import dagger.Module
import dagger.hilt.InstallIn
import dagger.hilt.components.SingletonComponent
import javax.inject.Singleton

@Module
@InstallIn(SingletonComponent::class)
abstract class RepositoryModule {
    @Binds @Singleton abstract fun tasks(impl: TasksRepositoryImpl): TasksRepository
    @Binds @Singleton abstract fun store(impl: MemoryStore): CacheStore
}
