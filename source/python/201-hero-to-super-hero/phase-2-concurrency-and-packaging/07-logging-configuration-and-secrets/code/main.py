import logging
import sys

from settings import Settings

logger = logging.getLogger("notes")


def report_startup(settings: Settings) -> None:
    logger.info("startup batch_size=%s", settings.batch_size)


def main() -> None:
    settings = Settings()
    logging.basicConfig(
        level=settings.log_level,
        format="%(levelname)s %(name)s %(message)s",
        stream=sys.stdout,
    )
    report_startup(settings)
    print(f"secret redacted: {settings.api_key}")


if __name__ == "__main__":
    main()
