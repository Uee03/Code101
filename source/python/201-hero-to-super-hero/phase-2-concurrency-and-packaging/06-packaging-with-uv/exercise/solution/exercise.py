from note_words import count_words


def describe(text: str) -> str:
    return f"words: {count_words(text)}"


assert describe("Read docs") == "words: 2"
print(describe("Read docs"))
