package exercise03

fun shortTitles(titles: List<String>, maxLength: Int): List<String> {
    return titles.filter { it.length <= maxLength }
}

fun main() {
    val titles = listOf("Buy milk", "Call dentist", "Pay rent")
    println(shortTitles(titles, 9))
}
