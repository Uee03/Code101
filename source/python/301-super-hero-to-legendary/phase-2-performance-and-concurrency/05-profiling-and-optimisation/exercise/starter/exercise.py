from collections import Counter


def top_words_slow(words: list[str], n: int) -> list[tuple[str, int]]:
    counts = {word: words.count(word) for word in set(words)}
    return sorted(counts.items(), key=lambda item: (-item[1], item[0]))[:n]


def top_words_fast(words: list[str], n: int) -> list[tuple[str, int]]:
    # TODO 1: count the words once with Counter(words)
    # TODO 2: sort by highest count first, ties alphabetical (most_common does NOT break ties alphabetically)
    # TODO 3: return the first n items
    raise NotImplementedError


if __name__ == "__main__":
    words = "to be or not to be that is the question to be".split()
    slow = top_words_slow(words, 3)
    fast = top_words_fast(words, 3)
    print(fast)
    print("same result:", slow == fast)
