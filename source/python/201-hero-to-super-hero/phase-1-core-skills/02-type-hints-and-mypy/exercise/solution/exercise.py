def first_title(titles: list[str]) -> str | None:
    if not titles:
        return None
    return titles[0]


def label(titles: list[str]) -> str:
    title = first_title(titles)
    if title is None:
        return "empty"
    return title.upper()


assert label([]) == "empty"
assert label(["Read"]) == "READ"
print(label([]), label(["Read"]))
