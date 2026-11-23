package exercise02

fun main() {
    val itemName = "tea bags"
    var stock = 40
    val sold = 7

    stock = stock - sold
    println("$itemName left: $stock")

    val nickname: String? = null
    println(nickname ?: "no nickname")
}
