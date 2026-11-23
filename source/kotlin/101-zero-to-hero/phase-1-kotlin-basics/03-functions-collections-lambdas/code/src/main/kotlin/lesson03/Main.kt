package lesson03

fun greet(name: String, greeting: String = "Hello"): String {
    return "$greeting, $name!"
}

fun twice(n: Int) = n * 2

fun describePriority(level: Int): String = when (level) {
    1 -> "low"
    2 -> "medium"
    3 -> "high"
    else -> "unknown"
}

fun main() {
    println(greet("Ana"))
    println(greet("Ben", greeting = "Welcome"))
    println(twice(21))
    println(describePriority(3))

    val titles = listOf("Buy milk", "Call dentist", "Water plants", "Pay rent")
    println(titles.size)
    println(titles[1])
    for (title in titles) {
        println("- $title")
    }

    val shopping = mutableListOf("tea", "sugar")
    shopping.add("lemons")
    shopping.remove("sugar")
    println(shopping)

    val stock = mapOf("tea" to 40, "sugar" to 12)
    println(stock["tea"])
    println(stock["salt"] ?: 0)
    for ((item, count) in stock) {
        println("$item: $count")
    }

    val numbers = listOf(5, 12, 8, 21, 3)
    val big = numbers.filter { it > 7 }
    val doubled = numbers.map { it * 2 }
    val sorted = numbers.sortedBy { it }
    println(big)
    println(doubled)
    println(sorted)
    println(numbers.sum())

    val shouted = titles.map { title -> title.uppercase() }
    println(shouted)
    val long = titles.filter { it.length > 10 }
    println(long)
}
