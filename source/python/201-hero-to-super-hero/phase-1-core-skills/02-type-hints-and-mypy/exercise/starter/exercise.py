def first_title(titles: list[str]) -> str | None:
    # TODO: return the first title, or None when the list is empty.
    return None


def label(titles: list[str]) -> str:
    title = first_title(titles)
    # TODO: narrow the possible None before calling upper().
    return "empty"


assert label([]) == "empty"
assert label(["Read"]) == "READ"
print(label([]), label(["Read"]))
