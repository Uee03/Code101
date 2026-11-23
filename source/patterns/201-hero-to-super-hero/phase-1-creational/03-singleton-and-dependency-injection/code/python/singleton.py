class Settings:
    _instance = None

    def __init__(self) -> None:
        self.tax_percent = 20

    @classmethod
    def instance(cls) -> "Settings":
        if cls._instance is None:
            cls._instance = cls()
        return cls._instance


def total_with_tax(net_cents: int) -> int:
    return net_cents + net_cents * Settings.instance().tax_percent // 100


def demo() -> None:
    first = Settings.instance()
    second = Settings.instance()
    print(f"same instance: {first is second}")
    print(f"total: {total_with_tax(1000)}")
    first.tax_percent = 0
    print(f"total after a change elsewhere: {total_with_tax(1000)}")
