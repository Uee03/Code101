package com.code101.tasks.domain.repository

import com.code101.tasks.domain.model.Profile

interface AccountRepository {
    suspend fun profile(): Profile

    suspend fun clearOfflineData()
}
