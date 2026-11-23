package com.code101.tasks.ui.tasks

import com.code101.tasks.domain.model.TaskItem
import kotlinx.coroutines.flow.Flow

// TODO: map each list of tasks to the number of tasks that are not "done" and not "cancelled",
// and let the flow emit only when that number really changes
fun Flow<List<TaskItem>>.toOpenCount(): Flow<Int> = this as Flow<Int>
