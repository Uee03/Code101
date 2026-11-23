package com.code101.tasks.domain.model

fun List<TaskItem>.openCount(): Int =
    count { it.status != "done" && it.status != "cancelled" }
