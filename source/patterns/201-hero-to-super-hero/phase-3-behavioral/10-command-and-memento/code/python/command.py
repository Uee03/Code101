from abc import ABC, abstractmethod


class Editor:
    def __init__(self) -> None:
        self.text = ""


class Command(ABC):
    @abstractmethod
    def execute(self) -> None:
        ...

    @abstractmethod
    def undo(self) -> None:
        ...


class Append(Command):
    def __init__(self, editor: Editor, text: str) -> None:
        self._editor = editor
        self._text = text

    def execute(self) -> None:
        self._editor.text += self._text

    def undo(self) -> None:
        keep = len(self._editor.text) - len(self._text)
        self._editor.text = self._editor.text[:keep]


class Uppercase(Command):
    def __init__(self, editor: Editor) -> None:
        self._editor = editor
        self._before = ""

    def execute(self) -> None:
        self._before = self._editor.text
        self._editor.text = self._editor.text.upper()

    def undo(self) -> None:
        self._editor.text = self._before


class History:
    def __init__(self) -> None:
        self._done: list[Command] = []

    def run(self, command: Command) -> None:
        command.execute()
        self._done.append(command)

    def undo(self) -> bool:
        if not self._done:
            return False
        self._done.pop().undo()
        return True


def demo() -> None:
    editor = Editor()
    history = History()
    history.run(Append(editor, "Hello"))
    history.run(Append(editor, ", world"))
    print(f"text: [{editor.text}]")
    history.run(Uppercase(editor))
    print(f"text: [{editor.text}]")
    history.undo()
    print(f"text: [{editor.text}]")
    history.undo()
    print(f"text: [{editor.text}]")
    history.undo()
    print(f"text: [{editor.text}]")
    print(f"undo possible: {history.undo()}")
