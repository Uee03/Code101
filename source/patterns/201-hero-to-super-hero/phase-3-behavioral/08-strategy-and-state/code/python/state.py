class State:
    name = ""

    def submit(self, doc: "Document") -> None:
        raise ValueError(f"Cannot submit a {self.name} document")

    def approve(self, doc: "Document") -> None:
        raise ValueError(f"Cannot approve a {self.name} document")

    def reject(self, doc: "Document") -> None:
        raise ValueError(f"Cannot reject a {self.name} document")


class Draft(State):
    name = "draft"

    def submit(self, doc: "Document") -> None:
        doc.set_state(InReview())


class InReview(State):
    name = "review"

    def approve(self, doc: "Document") -> None:
        doc.set_state(Published())

    def reject(self, doc: "Document") -> None:
        doc.set_state(Draft())


class Published(State):
    name = "published"


class Document:
    def __init__(self) -> None:
        self._state: State = Draft()

    def set_state(self, state: State) -> None:
        self._state = state

    def status(self) -> str:
        return self._state.name

    def submit(self) -> None:
        self._state.submit(self)

    def approve(self) -> None:
        self._state.approve(self)

    def reject(self) -> None:
        self._state.reject(self)


def demo() -> None:
    doc = Document()
    print(f"status: {doc.status()}")
    doc.submit()
    print(f"status: {doc.status()}")
    doc.reject()
    print(f"status: {doc.status()}")
    doc.submit()
    doc.approve()
    print(f"status: {doc.status()}")
    try:
        doc.submit()
    except ValueError as error:
        print(f"Error: {error}")
