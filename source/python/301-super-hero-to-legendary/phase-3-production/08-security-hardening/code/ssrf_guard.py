import ipaddress
import socket
from collections.abc import Callable
from dataclasses import dataclass
from urllib.parse import urlsplit

Resolver = Callable[[str, int], list]


class UnsafeUrl(ValueError):
    """The URL must not be fetched by the server."""


@dataclass(frozen=True)
class Target:
    host: str
    port: int
    address: str


def is_public(address: str) -> bool:
    ip = ipaddress.ip_address(address.split("%")[0])
    if isinstance(ip, ipaddress.IPv6Address) and ip.ipv4_mapped is not None:
        ip = ip.ipv4_mapped
    return ip.is_global and not ip.is_multicast


def validate_outbound_url(
    url: str, allowed_hosts: set[str], resolver: Resolver = socket.getaddrinfo
) -> Target:
    try:
        parts = urlsplit(url)
    except ValueError as error:
        raise UnsafeUrl("the URL cannot be parsed") from error
    if parts.scheme != "https":
        raise UnsafeUrl("only https is allowed")
    if parts.username or parts.password:
        raise UnsafeUrl("credentials in the URL are not allowed")
    host = (parts.hostname or "").lower()
    if host not in allowed_hosts:
        raise UnsafeUrl(f"host {host!r} is not on the allow-list")
    try:
        port = parts.port or 443
    except ValueError as error:
        raise UnsafeUrl("the port is not a valid number") from error
    addresses = [info[4][0] for info in resolver(host, port)]
    if not addresses:
        raise UnsafeUrl(f"{host} did not resolve")
    for address in addresses:
        if not is_public(address):
            raise UnsafeUrl(f"{host} resolves to a non-public address")
    return Target(host, port, addresses[0])
