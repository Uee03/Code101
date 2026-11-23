import re
from urllib.parse import urlparse

URL = re.compile(r"https?://[^\s)\]>\"']+", re.IGNORECASE)


def extract_hosts(text):
    """Return the set of lower-case host names of every http or https URL in text."""
    # TODO 1: find every URL with URL.findall(text)
    # TODO 2: parse each one with urlparse and collect its lower-case hostname (skip URLs without one)
    return set()
