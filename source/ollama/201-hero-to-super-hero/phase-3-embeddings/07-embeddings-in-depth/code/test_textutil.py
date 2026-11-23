import unittest

from textutil import chunk_words, cosine, cosine_rank, dot, normalise, norm, split_paragraphs


class VectorTests(unittest.TestCase):
    def test_dot_and_norm(self):
        self.assertEqual(dot([1, 2, 3], [4, 5, 6]), 32)
        self.assertEqual(norm([3, 4]), 5.0)

    def test_normalise_gives_unit_length(self):
        result = normalise([3, 4])
        self.assertAlmostEqual(result[0], 0.6)
        self.assertAlmostEqual(result[1], 0.8)
        self.assertAlmostEqual(norm(result), 1.0)

    def test_normalise_rejects_zero_vector(self):
        with self.assertRaises(ValueError):
            normalise([0, 0])

    def test_cosine_of_same_and_perpendicular_directions(self):
        self.assertAlmostEqual(cosine([1, 0], [2, 0]), 1.0)
        self.assertAlmostEqual(cosine([1, 0], [0, 1]), 0.0)

    def test_cosine_rejects_unequal_lengths(self):
        with self.assertRaises(ValueError):
            cosine([1, 2], [1, 2, 3])

    def test_dot_of_unit_vectors_equals_cosine(self):
        left, right = [1, 2, 3], [4, 5, 6]
        self.assertAlmostEqual(dot(normalise(left), normalise(right)), cosine(left, right))

    def test_rank_orders_by_similarity(self):
        self.assertEqual(cosine_rank([1, 0], [[0, 1], [1, 0], [1, 1]]), [1, 2, 0])


class ChunkTests(unittest.TestCase):
    def test_overlap_repeats_words(self):
        self.assertEqual(chunk_words("aa bb cc dd ee ff", 8, 1), ["aa bb cc", "cc dd ee", "ee ff"])

    def test_no_overlap_partitions_the_text(self):
        self.assertEqual(chunk_words("aa bb cc dd ee ff", 8, 0), ["aa bb cc", "dd ee ff"])

    def test_a_long_word_gets_its_own_chunk(self):
        self.assertEqual(chunk_words("abcdefghij kl", 5, 0), ["abcdefghij", "kl"])

    def test_every_word_is_covered(self):
        text = " ".join(f"w{number}" for number in range(20))
        chunks = chunk_words(text, 12, 2)
        covered = {word for chunk in chunks for word in chunk.split()}
        self.assertEqual(covered, set(text.split()))

    def test_bad_settings_are_rejected(self):
        with self.assertRaises(ValueError):
            chunk_words("a b", 0, 0)
        with self.assertRaises(ValueError):
            chunk_words("a b", 5, -1)

    def test_paragraphs(self):
        self.assertEqual(split_paragraphs("One.\n\nTwo\nlines.\n\n\nThree."), ["One.", "Two\nlines.", "Three."])


if __name__ == "__main__":
    unittest.main()
