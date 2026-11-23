package com.code101.tasks.data.remote

import com.code101.tasks.domain.model.*
import kotlinx.serialization.json.*
import retrofit2.Response
import java.time.ZonedDateTime
import java.time.format.DateTimeFormatter

object ProblemParser {
    fun parse(response: Response<*>): ApiProblem {
        val json = runCatching { wireJson.parseToJsonElement(response.errorBody()?.string().orEmpty()).jsonObject }.getOrNull()
        val delay = response.headers()["Retry-After"]
        val retryAt = delay?.toLongOrNull()?.let { System.currentTimeMillis() + it * 1000 }
            ?: runCatching { ZonedDateTime.parse(delay, DateTimeFormatter.RFC_1123_DATE_TIME).toInstant().toEpochMilli() }.getOrDefault(0)
        val errors = (json?.get("errors") as? JsonArray).orEmpty().mapNotNull { item ->
            val o = item as? JsonObject ?: return@mapNotNull null
            FieldError(o["pointer"]?.jsonPrimitive?.content.orEmpty(), o["detail"]?.jsonPrimitive?.content.orEmpty())
        }
        return ApiProblem(json?.get("type")?.jsonPrimitive?.content.orEmpty(),
            json?.get("title")?.jsonPrimitive?.content ?: response.message(), response.code(), errors,
            retryAt, json?.get("traceId")?.jsonPrimitive?.contentOrNull)
    }
}
fun <T> Response<T>.required(): T {
    if (!isSuccessful) throw ApiFailure(ProblemParser.parse(this))
    return body() ?: throw java.io.IOException("Empty response")
}
