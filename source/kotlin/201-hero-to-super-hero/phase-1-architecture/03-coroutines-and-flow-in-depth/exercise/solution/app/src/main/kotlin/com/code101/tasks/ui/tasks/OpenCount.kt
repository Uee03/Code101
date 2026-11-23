package com.code101.tasks.ui.tasks

import com.code101.tasks.domain.model.TaskItem
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.distinctUntilChanged
import kotlinx.coroutines.flow.map

fun Flow<List<TaskItem>>.toOpenCount(): Flow<Int> =
    map { tasks -> tasks.count { it.status != "done" && it.status != "cancelled" } }
        .distinctUntilChanged()
