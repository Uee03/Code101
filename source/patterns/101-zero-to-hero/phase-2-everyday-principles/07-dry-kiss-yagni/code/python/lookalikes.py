def length_problem(text, minimum, maximum):
    if len(text) < minimum or len(text) > maximum:
        return f"must be {minimum} to {maximum} characters"
    return ""


def username_problem(name):
    return length_problem(name, 3, 20)


def product_title_problem(title):
    return length_problem(title, 3, 60)
