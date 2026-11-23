package exercise04

data class Book(val title: String, val pages: Int, val read: Boolean = false)

class Shelf {
    private val books = mutableListOf<Book>()

    fun add(book: Book) {
        // TODO 1: put the book into the books list
    }

    fun unreadTitles(): List<String> {
        // TODO 2: return the titles of the books that are not read yet
        return emptyList()
    }
}

fun main() {
    val shelf = Shelf()
    shelf.add(Book("Dune", 612))
    shelf.add(Book("Emma", 474, read = true))
    shelf.add(Book("Kim", 320))
    println(shelf.unreadTitles())
}
