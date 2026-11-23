from collections import Counter


def top_words_slow(words: list[str], n: int) -> list[tuple[str, int]]:
    counts = {word: words.count(word) for word in set(words)}
    return sorted(counts.items(), key=lambda item: (-item[1], item[0]))[:n]


def top_words_fast(words: list[str], n: int) -> list[tuple[str, int]]:
    counts = Counter(words)
    return sorted(counts.items(), key=lambda item: (-item[1], item[0]))[:n]


if __name__ == "__main__":
    words = "to be or not to be that is the question to be".split()
    slow = top_words_slow(words, 3)
    fast = top_words_fast(words, 3)
    print(fast)
    print("same result:", slow == fast)
