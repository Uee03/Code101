package lesson04

enum class Priority { LOW, MEDIUM, HIGH }

data class Task(
    val id: Int,
    val title: String,
    val priority: Priority = Priority.MEDIUM,
    val done: Boolean = false,
)

class TaskList {
    private val tasks = mutableListOf<Task>()

    fun add(title: String, priority: Priority = Priority.MEDIUM): Task {
        val task = Task(id = tasks.size + 1, title = title, priority = priority)
        tasks.add(task)
        return task
    }

    fun complete(id: Int) {
        val index = tasks.indexOfFirst { it.id == id }
        if (index >= 0) {
            tasks[index] = tasks[index].copy(done = true)
        }
    }

    fun all(): List<Task> = tasks.toList()

    fun openCount(): Int = tasks.count { !it.done }
}

object Defaults {
    const val MAX_TITLE_LENGTH = 40

    fun clean(title: String): String = title.trim().take(MAX_TITLE_LENGTH)
}

sealed interface LoadState {
    data object Loading : LoadState
    data class Done(val tasks: List<Task>) : LoadState
    data class Failed(val message: String) : LoadState
}
