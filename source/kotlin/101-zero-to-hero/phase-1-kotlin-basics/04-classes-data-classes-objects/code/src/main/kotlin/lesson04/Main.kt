package lesson04

fun describe(state: LoadState): String = when (state) {
    LoadState.Loading -> "Loading..."
    is LoadState.Done -> "Loaded ${state.tasks.size} tasks"
    is LoadState.Failed -> "Problem: ${state.message}"
}

fun main() {
    val list = TaskList()
    list.add(Defaults.clean("  Buy milk  "))
    list.add("Call dentist", Priority.HIGH)
    val rent = list.add("Pay rent")
    list.complete(rent.id)

    for (task in list.all()) {
        println(task)
    }
    println("Open tasks: ${list.openCount()}")

    val first = list.all().first()
    val renamed = first.copy(title = "Buy oat milk")
    println(first == renamed)
    println(first == first.copy())
    println(renamed)

    println(describe(LoadState.Loading))
    println(describe(LoadState.Done(list.all())))
    println(describe(LoadState.Failed("no network")))
}
