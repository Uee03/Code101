import re
from urllib.parse import urlparse

URL = re.compile(r"https?://[^\s)\]>\"']+", re.IGNORECASE)


def extract_hosts(text):
    """Return the set of lower-case host names of every http or https URL in text."""
    hosts = set()
    for url in URL.findall(text):
        host = urlparse(url).hostname
        if host:
            hosts.add(host.lower())
    return hosts
