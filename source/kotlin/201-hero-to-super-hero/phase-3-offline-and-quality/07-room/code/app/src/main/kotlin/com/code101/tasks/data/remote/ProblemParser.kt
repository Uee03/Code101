package com.code101.tasks.data.remote

import com.code101.tasks.domain.model.ApiFailure
import com.code101.tasks.domain.model.ApiProblem
import com.code101.tasks.domain.model.FieldError
import java.io.IOException
import java.time.ZonedDateTime
import java.time.format.DateTimeFormatter
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.contentOrNull
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive
import retrofit2.Response

object ProblemParser {
    fun parse(response: Response<*>): ApiProblem {
        val json = runCatching {
            wireJson.parseToJsonElement(response.errorBody()?.string().orEmpty()).jsonObject
        }.getOrNull()

        val header = response.headers()["Retry-After"]
        val retryAfter = header?.toLongOrNull()?.let { seconds -> seconds * 1000 }
            ?: runCatching {
                ZonedDateTime.parse(header, DateTimeFormatter.RFC_1123_DATE_TIME)
                    .toInstant().toEpochMilli() - System.currentTimeMillis()
            }.getOrDefault(0L)

        val errors = (json?.get("errors") as? JsonArray).orEmpty().mapNotNull { item ->
            val obj = item as? JsonObject ?: return@mapNotNull null
            FieldError(
                pointer = obj["pointer"]?.jsonPrimitive?.content.orEmpty(),
                detail = obj["detail"]?.jsonPrimitive?.content.orEmpty(),
            )
        }

        return ApiProblem(
            type = json?.get("type")?.jsonPrimitive?.content.orEmpty(),
            title = json?.get("title")?.jsonPrimitive?.contentOrNull ?: response.message(),
            status = response.code(),
            errors = errors,
            retryAfterMillis = retryAfter.coerceAtLeast(0L),
            traceId = json?.get("traceId")?.jsonPrimitive?.contentOrNull,
        )
    }
}

fun <T> Response<T>.required(): T {
    if (!isSuccessful) throw ApiFailure(ProblemParser.parse(this))
    return body() ?: throw IOException("Empty response")
}
