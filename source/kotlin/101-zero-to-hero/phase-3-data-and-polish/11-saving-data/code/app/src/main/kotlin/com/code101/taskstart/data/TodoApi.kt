package com.code101.taskstart.data

import retrofit2.http.GET
import retrofit2.http.Query

interface TodoApi {
    @GET("todos")
    suspend fun todos(@Query("_limit") limit: Int): List<TodoDto>
}
