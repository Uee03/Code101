import cProfile
import pstats

from report import customers_slow, make_rows


def main() -> None:
    rows = make_rows(20_000)
    profiler = cProfile.Profile()
    profiler.enable()
    customers_slow(rows)
    profiler.disable()
    pstats.Stats(profiler).sort_stats("cumulative").print_stats(5)


if __name__ == "__main__":
    main()
