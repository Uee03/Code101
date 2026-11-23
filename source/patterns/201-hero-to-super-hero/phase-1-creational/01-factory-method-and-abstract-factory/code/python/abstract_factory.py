from abc import ABC, abstractmethod


class Button(ABC):
    @abstractmethod
    def render(self) -> str:
        ...


class Checkbox(ABC):
    @abstractmethod
    def render(self) -> str:
        ...


class LightButton(Button):
    def render(self) -> str:
        return "light button"


class LightCheckbox(Checkbox):
    def render(self) -> str:
        return "light checkbox"


class DarkButton(Button):
    def render(self) -> str:
        return "dark button"


class DarkCheckbox(Checkbox):
    def render(self) -> str:
        return "dark checkbox"


class ThemeFactory(ABC):
    @abstractmethod
    def create_button(self) -> Button:
        ...

    @abstractmethod
    def create_checkbox(self) -> Checkbox:
        ...


class LightTheme(ThemeFactory):
    def create_button(self) -> Button:
        return LightButton()

    def create_checkbox(self) -> Checkbox:
        return LightCheckbox()


class DarkTheme(ThemeFactory):
    def create_button(self) -> Button:
        return DarkButton()

    def create_checkbox(self) -> Checkbox:
        return DarkCheckbox()


def render_form(theme: ThemeFactory) -> str:
    button = theme.create_button()
    checkbox = theme.create_checkbox()
    return f"{button.render()} + {checkbox.render()}"


def demo() -> None:
    for name, theme in (("light", LightTheme()), ("dark", DarkTheme())):
        print(f"{name}: {render_form(theme)}")
