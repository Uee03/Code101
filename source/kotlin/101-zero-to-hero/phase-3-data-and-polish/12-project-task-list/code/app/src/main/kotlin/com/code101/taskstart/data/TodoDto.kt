package com.code101.taskstart.data

import kotlinx.serialization.Serializable

@Serializable
data class TodoDto(
    val id: Int,
    val title: String,
    val completed: Boolean,
)
