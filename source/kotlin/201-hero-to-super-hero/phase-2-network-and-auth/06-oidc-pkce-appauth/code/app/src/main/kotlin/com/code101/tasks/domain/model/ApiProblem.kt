package com.code101.tasks.domain.model

data class FieldError(val pointer: String, val detail: String)

data class ApiProblem(
    val type: String,
    val title: String,
    val status: Int,
    val errors: List<FieldError> = emptyList(),
    val retryAfterMillis: Long = 0,
    val traceId: String? = null,
)

class ApiFailure(val problem: ApiProblem) : Exception(problem.title)
