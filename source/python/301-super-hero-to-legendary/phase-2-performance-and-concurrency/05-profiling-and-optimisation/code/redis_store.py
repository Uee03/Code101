import logging

import redis

logger = logging.getLogger(__name__)


class RedisStore:
    def __init__(self, url: str) -> None:
        self._client = redis.Redis.from_url(
            url, decode_responses=True, socket_connect_timeout=0.5, socket_timeout=0.5
        )

    def get(self, key: str) -> str | None:
        try:
            value = self._client.get(key)
        except redis.RedisError:
            logger.warning("cache read failed, falling back to the source", exc_info=True)
            return None
        return value if isinstance(value, str) else None

    def set(self, key: str, value: str, ttl_seconds: int) -> None:
        try:
            self._client.set(key, value, ex=ttl_seconds)
        except redis.RedisError:
            logger.warning("cache write failed, continuing without the cache", exc_info=True)
