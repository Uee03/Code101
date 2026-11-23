package com.code101.taskstart.model

data class Task(
    val id: Int,
    val title: String,
    val done: Boolean = false,
)
