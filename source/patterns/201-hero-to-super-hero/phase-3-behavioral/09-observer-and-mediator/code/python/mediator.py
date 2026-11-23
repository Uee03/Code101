from abc import ABC, abstractmethod


class Mediator(ABC):
    @abstractmethod
    def changed(self, sender: "Component") -> None:
        ...


class Component:
    def __init__(self, mediator: Mediator, label: str) -> None:
        self._mediator = mediator
        self.label = label

    def _notify(self) -> None:
        self._mediator.changed(self)


class TextBox(Component):
    def __init__(self, mediator: Mediator, label: str) -> None:
        super().__init__(mediator, label)
        self.text = ""

    def set_text(self, text: str) -> None:
        self.text = text
        self._notify()


class Checkbox(Component):
    def __init__(self, mediator: Mediator, label: str) -> None:
        super().__init__(mediator, label)
        self.checked = False

    def set_checked(self, value: bool) -> None:
        self.checked = value
        self._notify()


class SignupForm(Mediator):
    def __init__(self) -> None:
        self.name = TextBox(self, "name")
        self.terms = Checkbox(self, "terms")
        self.register_enabled = False

    def changed(self, sender: Component) -> None:
        self.register_enabled = len(self.name.text) > 0 and self.terms.checked
        print(f"{sender.label} changed -> register enabled: {self.register_enabled}")


def demo() -> None:
    form = SignupForm()
    form.name.set_text("ana")
    form.terms.set_checked(True)
    form.name.set_text("")
