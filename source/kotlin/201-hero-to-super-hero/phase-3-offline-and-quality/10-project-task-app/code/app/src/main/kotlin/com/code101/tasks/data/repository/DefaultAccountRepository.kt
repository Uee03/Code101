package com.code101.tasks.data.repository

import com.code101.tasks.data.local.TasksDatabase
import com.code101.tasks.data.remote.RemoteDataSource
import com.code101.tasks.di.IoDispatcher
import com.code101.tasks.domain.model.Profile
import com.code101.tasks.domain.repository.AccountRepository
import javax.inject.Inject
import kotlinx.coroutines.CoroutineDispatcher
import kotlinx.coroutines.withContext

class DefaultAccountRepository @Inject constructor(
    private val remote: RemoteDataSource,
    private val database: TasksDatabase,
    @IoDispatcher private val io: CoroutineDispatcher,
) : AccountRepository {
    override suspend fun profile(): Profile = remote.me()

    override suspend fun clearOfflineData() {
        withContext(io) { database.clearAllTables() }
    }
}
