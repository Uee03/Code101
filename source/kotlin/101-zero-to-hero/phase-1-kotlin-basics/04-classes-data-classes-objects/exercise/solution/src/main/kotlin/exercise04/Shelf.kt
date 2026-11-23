package exercise04

data class Book(val title: String, val pages: Int, val read: Boolean = false)

class Shelf {
    private val books = mutableListOf<Book>()

    fun add(book: Book) {
        books.add(book)
    }

    fun unreadTitles(): List<String> {
        return books.filter { !it.read }.map { it.title }
    }
}

fun main() {
    val shelf = Shelf()
    shelf.add(Book("Dune", 612))
    shelf.add(Book("Emma", 474, read = true))
    shelf.add(Book("Kim", 320))
    println(shelf.unreadTitles())
}
