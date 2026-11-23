from dataclasses import dataclass
from typing import Optional


@dataclass(frozen=True)
class Computer:
    cpu: str
    ram_gb: int
    storage_gb: int
    gpu: Optional[str]

    def describe(self) -> str:
        gpu = self.gpu if self.gpu is not None else "no GPU"
        return f"{self.cpu}, {self.ram_gb} GB RAM, {self.storage_gb} GB storage, {gpu}"


class ComputerBuilder:
    def __init__(self) -> None:
        self._cpu = "basic CPU"
        self._ram_gb = 8
        self._storage_gb = 256
        self._gpu: Optional[str] = None

    def with_cpu(self, cpu: str) -> "ComputerBuilder":
        self._cpu = cpu
        return self

    def with_ram(self, ram_gb: int) -> "ComputerBuilder":
        self._ram_gb = ram_gb
        return self

    def with_storage(self, storage_gb: int) -> "ComputerBuilder":
        self._storage_gb = storage_gb
        return self

    def with_gpu(self, gpu: str) -> "ComputerBuilder":
        self._gpu = gpu
        return self

    def build(self) -> Computer:
        if self._ram_gb < 4:
            raise ValueError("at least 4 GB RAM is required")
        return Computer(self._cpu, self._ram_gb, self._storage_gb, self._gpu)


class Director:
    @staticmethod
    def office_pc(builder: ComputerBuilder) -> Computer:
        return builder.with_ram(16).build()

    @staticmethod
    def gaming_pc(builder: ComputerBuilder) -> Computer:
        return builder.with_cpu("fast CPU").with_ram(32).with_storage(2000).with_gpu("big GPU").build()


def demo() -> None:
    print(f"office: {Director.office_pc(ComputerBuilder()).describe()}")
    print(f"gaming: {Director.gaming_pc(ComputerBuilder()).describe()}")
    try:
        ComputerBuilder().with_ram(2).build()
    except ValueError as error:
        print(f"Rejected: {error}")
