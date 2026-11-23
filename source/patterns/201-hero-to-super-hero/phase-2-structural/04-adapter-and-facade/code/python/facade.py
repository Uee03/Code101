class Amplifier:
    def on(self, volume: int) -> None:
        print(f"Amplifier: on, volume {volume}")

    def off(self) -> None:
        print("Amplifier: off")


class Projector:
    def on(self, source: str) -> None:
        print(f"Projector: on, input {source}")

    def off(self) -> None:
        print("Projector: off")


class Player:
    def play(self, title: str) -> None:
        print(f"Player: playing {title}")

    def stop(self) -> None:
        print("Player: stopped")


class HomeTheater:
    def __init__(self, amplifier: Amplifier, projector: Projector, player: Player) -> None:
        self._amplifier = amplifier
        self._projector = projector
        self._player = player

    def watch(self, title: str) -> None:
        self._amplifier.on(5)
        self._projector.on("player")
        self._player.play(title)

    def end(self) -> None:
        self._player.stop()
        self._projector.off()
        self._amplifier.off()


def demo() -> None:
    theater = HomeTheater(Amplifier(), Projector(), Player())
    theater.watch("Matrix")
    theater.end()
