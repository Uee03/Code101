package com.code101.tasks.data.remote

import com.code101.tasks.generated.api.PlatformApi
import java.io.IOException
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class RemoteDataSource @Inject constructor(
    private val platformApi: PlatformApi,
) {
    suspend fun health(): String {
        val response = platformApi.getHealth()
        if (!response.isSuccessful) throw IOException("Health returned ${response.code()}")
        val body = response.body() ?: throw IOException("Empty health body")
        return body.database?.value ?: body.status.value
    }

    suspend fun callerName(): String {
        val response = platformApi.getMe()
        if (!response.isSuccessful) throw IOException("Me returned ${response.code()}")
        val body = response.body() ?: throw IOException("Empty me body")
        return body.displayName
    }
}
