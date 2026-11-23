package lesson02

fun main() {
    val shopName = "Corner Cafe"
    var cupsSold = 12
    val pricePerCup = 2.5
    val isOpen = true
    val grade = 'A'

    cupsSold = cupsSold + 3
    val total = cupsSold * pricePerCup

    println("$shopName is open: $isOpen")
    println("Cups sold: $cupsSold")
    println("Total: $total")
    println("Whole cups per pair: ${cupsSold / 2}")
    println("Exact cups per pair: ${cupsSold / 2.0}")
    println("Shop name has ${shopName.length} letters")
    println("Grade: $grade")

    val dayType = if (cupsSold >= 10) "busy" else "quiet"
    println("Today was $dayType")

    showNullSafety()
}

fun showNullSafety() {
    val typedAge: String? = "42"
    val missingAge: String? = null

    println(typedAge?.length)
    println(missingAge?.length)
    println(missingAge ?: "no age given")

    val age = typedAge?.toIntOrNull() ?: 0
    println("Age plus one: ${age + 1}")

    val notANumber = "forty".toIntOrNull()
    println(notANumber)

    if (typedAge != null) {
        println("Typed age uses ${typedAge.length} characters")
    }
}
