package com.code101.taskstart.data

import com.code101.taskstart.model.Task
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map

class TasksRepository(
    private val dao: TaskDao,
    private val settings: SettingsStore,
    private val api: TodoApi,
) {
    val tasks: Flow<List<Task>> = dao.observeAll().map { rows -> rows.map { it.toTask() } }
    val hideDone: Flow<Boolean> = settings.hideDone

    suspend fun add(title: String) = dao.insert(TaskEntity(title = title))

    suspend fun toggle(id: Int) = dao.toggle(id)

    suspend fun delete(id: Int) = dao.delete(id)

    suspend fun setHideDone(value: Boolean) = settings.setHideDone(value)

    suspend fun importSamples(limit: Int): Int {
        val todos = api.todos(limit)
        dao.insertAll(todos.map { TaskEntity(title = it.title, done = it.completed) })
        return todos.size
    }
}
