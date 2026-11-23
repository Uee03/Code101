import unittest

from cache import CALLS, InMemoryStore, cached_lookup, tax_rate
from report import customers_fast, customers_slow, make_rows


class OptimisationKeepsBehaviourTests(unittest.TestCase):
    def test_fast_and_slow_agree_including_order(self) -> None:
        rows = make_rows(5_000)
        self.assertEqual(customers_fast(rows), customers_slow(rows))

    def test_first_seen_order_is_kept(self) -> None:
        self.assertEqual(customers_fast(make_rows(3)), ["c0", "c1", "c2"])


class LruCacheTests(unittest.TestCase):
    def setUp(self) -> None:
        tax_rate.cache_clear()
        CALLS["tax_rate"] = 0

    def test_repeated_arguments_hit_the_cache(self) -> None:
        for region in ["EU", "US", "EU", "EU"]:
            tax_rate(region)
        info = tax_rate.cache_info()
        self.assertEqual((info.hits, info.misses), (2, 2))
        self.assertEqual(CALLS["tax_rate"], 2)

    def test_exceptions_are_not_cached(self) -> None:
        for _ in range(2):
            with self.assertRaises(KeyError):
                tax_rate("MARS")
        self.assertEqual(CALLS["tax_rate"], 2)


class TtlCacheTests(unittest.TestCase):
    def setUp(self) -> None:
        self.now = [0.0]
        self.store = InMemoryStore(lambda: self.now[0])
        self.loads: list[int] = []

    def load(self) -> str:
        self.loads.append(1)
        return f"value-{len(self.loads)}"

    def test_a_fresh_entry_is_served_from_the_cache(self) -> None:
        cached_lookup(self.store, "k", self.load, ttl_seconds=60)
        self.now[0] = 59.0
        self.assertEqual(cached_lookup(self.store, "k", self.load, ttl_seconds=60), "value-1")
        self.assertEqual(len(self.loads), 1)

    def test_an_expired_entry_is_loaded_again(self) -> None:
        cached_lookup(self.store, "k", self.load, ttl_seconds=60)
        self.now[0] = 60.0
        self.assertEqual(cached_lookup(self.store, "k", self.load, ttl_seconds=60), "value-2")


if __name__ == "__main__":
    unittest.main()
