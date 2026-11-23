from app.main import greeting


def test_greeting_includes_name():
    assert greeting("Ada") == "Hello, Ada!"


def test_greeting_is_an_exclamation():
    assert greeting("x").endswith("!")
