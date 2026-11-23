# Design Patterns + SOLID glossary (level 101)

Plain-language definitions for Design Patterns + SOLID 101. Lesson links point to the first introduction.

| Term | Meaning | Lesson |
|---|---|---|
| Design | Arranging code so that changing one thing does not break others. | [01](101-zero-to-hero/phase-1-solid/01-why-design-matters.md) |
| Cohesion | How closely the parts inside one unit (function or class) belong together. High is good. | [01](101-zero-to-hero/phase-1-solid/01-why-design-matters.md) |
| Coupling | How much one unit depends on the details of another. Low is good. | [01](101-zero-to-hero/phase-1-solid/01-why-design-matters.md) |
| Code smell | A pattern in code that is not a bug but hints at a design problem. | [01](101-zero-to-hero/phase-1-solid/01-why-design-matters.md) |
| Long function | A smell: one function that does several jobs. | [01](101-zero-to-hero/phase-1-solid/01-why-design-matters.md) |
| Magic number | A bare number in code whose meaning is not named. | [01](101-zero-to-hero/phase-1-solid/01-why-design-matters.md) |
| Duplicated code | A smell: the same knowledge written in more than one place. | [01](101-zero-to-hero/phase-1-solid/01-why-design-matters.md) |
| Refactoring | Changing the structure of code without changing what it does; unchanged output is the proof. | [01](101-zero-to-hero/phase-1-solid/01-why-design-matters.md) |
| Tuple | A small fixed group of values, such as `(name, price in cents, quantity)`. | [01](101-zero-to-hero/phase-1-solid/01-why-design-matters.md) |
| Alias (C# `using Item = ...`) | A short nickname for a longer type. | [01](101-zero-to-hero/phase-1-solid/01-why-design-matters.md) |
| Namespace (C#) | A named group of types; `Before` and `After` keep two designs apart in one project. | [01](101-zero-to-hero/phase-1-solid/01-why-design-matters.md) |
| SOLID | Five principles: Single responsibility, Open/closed, Liskov substitution, Interface segregation, Dependency inversion. | [02](101-zero-to-hero/phase-1-solid/02-single-responsibility.md) |
| Single Responsibility Principle (SRP) | A class should have only one reason to change. | [02](101-zero-to-hero/phase-1-solid/02-single-responsibility.md) |
| Reason to change | A person or need that could ask for a change to a class (finance, design, storage, support). | [02](101-zero-to-hero/phase-1-solid/02-single-responsibility.md) |
| Attribute | A value stored on an object. | [02](101-zero-to-hero/phase-1-solid/02-single-responsibility.md) |
| Method | A function that belongs to a class. | [02](101-zero-to-hero/phase-1-solid/02-single-responsibility.md) |
| Property (C#) | An attribute that can be read from outside but is set only inside the class, such as `{ get; }`. | [02](101-zero-to-hero/phase-1-solid/02-single-responsibility.md) |
| Open/Closed Principle (OCP) | Code should be open for extension and closed for modification: add behaviour without editing code that works. | [03](101-zero-to-hero/phase-1-solid/03-open-closed.md) |
| Interface | A list of methods a class promises to have; it says what, not how. | [03](101-zero-to-hero/phase-1-solid/03-open-closed.md) |
| Implement | To keep an interface's promise by providing every listed method. | [03](101-zero-to-hero/phase-1-solid/03-open-closed.md) |
| Abstract base class (Python `ABC`) | A class that cannot be used directly and marks methods every subclass must provide. | [03](101-zero-to-hero/phase-1-solid/03-open-closed.md) |
| Polymorphism | Calling the same method on different objects, each doing its own thing. | [03](101-zero-to-hero/phase-1-solid/03-open-closed.md) |
| Dictionary | A collection that maps a key to a value; used here to replace an `if / elif` chain. | [03](101-zero-to-hero/phase-1-solid/03-open-closed.md) |
| Liskov Substitution Principle (LSP) | Wherever code accepts a parent type it must keep working with any child type. | [04](101-zero-to-hero/phase-1-solid/04-liskov-substitution.md) |
| Parent type / child type | A type another type is built from / a type that inherits from it. | [04](101-zero-to-hero/phase-1-solid/04-liskov-substitution.md) |
| Exception | The way a language stops normal flow when something goes wrong (`raise` / `throw`, `try` with `except` / `catch`). | [04](101-zero-to-hero/phase-1-solid/04-liskov-substitution.md) |
| Type hint | A note about the type a value should have, such as `payment: Refundable`; ignored by Python at run time, used by editors and checkers. | [04](101-zero-to-hero/phase-1-solid/04-liskov-substitution.md) |
| Interface Segregation Principle (ISP) | No class should be forced to depend on methods it does not use; prefer several small interfaces. | [05](101-zero-to-hero/phase-1-solid/05-interface-segregation.md) |
| Fat interface | An interface that lists many unrelated methods. | [05](101-zero-to-hero/phase-1-solid/05-interface-segregation.md) |
| Client (of an interface) | The code that uses the interface. | [05](101-zero-to-hero/phase-1-solid/05-interface-segregation.md) |
| Stub | A method that exists only to satisfy an interface and does nothing real. | [05](101-zero-to-hero/phase-1-solid/05-interface-segregation.md) |
| Role | One thing a class can do for a client; one small interface per role. | [05](101-zero-to-hero/phase-1-solid/05-interface-segregation.md) |
| Dependency | Anything a class needs to do its job: another class, a clock, a file, a network connection. | [06](101-zero-to-hero/phase-1-solid/06-dependency-inversion.md) |
| Dependency Inversion Principle (DIP) | High-level code should not depend on low-level details; both depend on abstractions. | [06](101-zero-to-hero/phase-1-solid/06-dependency-inversion.md) |
| Dependency injection (DI) | Passing a class its dependencies from outside instead of letting it create them. | [06](101-zero-to-hero/phase-1-solid/06-dependency-inversion.md) |
| Constructor | The method that runs when an object is created (`__init__` in Python). | [06](101-zero-to-hero/phase-1-solid/06-dependency-inversion.md) |
| Constructor injection | Handing dependencies to the constructor. | [06](101-zero-to-hero/phase-1-solid/06-dependency-inversion.md) |
| Fake | A simple stand-in object used in a check instead of the real thing; it records what it received. | [06](101-zero-to-hero/phase-1-solid/06-dependency-inversion.md) |
| Composition root | The one place near the start of the program that creates objects and connects them. | [06](101-zero-to-hero/phase-1-solid/06-dependency-inversion.md) |
| DI container | A tool that does the wiring of dependencies automatically; not used at this level. | [06](101-zero-to-hero/phase-1-solid/06-dependency-inversion.md) |
| DRY | Don't Repeat Yourself: every piece of knowledge has one home. | [07](101-zero-to-hero/phase-2-everyday-principles/07-dry-kiss-yagni.md) |
| KISS | Keep It Simple: choose the plainest code that does the job. | [07](101-zero-to-hero/phase-2-everyday-principles/07-dry-kiss-yagni.md) |
| YAGNI | You Aren't Gonna Need It: do not build features before you need them. | [07](101-zero-to-hero/phase-2-everyday-principles/07-dry-kiss-yagni.md) |
| Accidental duplication | Two pieces of code that look alike today but change for different reasons; do not merge them. | [07](101-zero-to-hero/phase-2-everyday-principles/07-dry-kiss-yagni.md) |
| Rule of three | Write it, copy it once, extract it the third time. | [07](101-zero-to-hero/phase-2-everyday-principles/07-dry-kiss-yagni.md) |
| Lambda | A tiny nameless function written inline. | [07](101-zero-to-hero/phase-2-everyday-principles/07-dry-kiss-yagni.md) |
| Inheritance (is a) | A class gets behaviour by being a kind of another class. | [08](101-zero-to-hero/phase-2-everyday-principles/08-composition-over-inheritance.md) |
| Composition (has a) | A class gets behaviour by holding other objects and asking them to do the work. | [08](101-zero-to-hero/phase-2-everyday-principles/08-composition-over-inheritance.md) |
| Strategy pattern | Swapping an interchangeable part at run time; named here, taught in level 201. | [08](101-zero-to-hero/phase-2-everyday-principles/08-composition-over-inheritance.md) |
| Class diagram | A drawing of classes and the relationships between them. | [09](101-zero-to-hero/phase-2-everyday-principles/09-class-diagrams-and-review.md) |
| Mermaid | A text format for diagrams that renders in Markdown previews and on GitHub. | [09](101-zero-to-hero/phase-2-everyday-principles/09-class-diagrams-and-review.md) |
| Association / dependency / aggregation / composition / realization arrows | `-->` uses, `..>` uses briefly, `o--` has (can live apart), `*--` owns, `<\|..` implements. | [09](101-zero-to-hero/phase-2-everyday-principles/09-class-diagrams-and-review.md) |
