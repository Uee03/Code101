# Design Patterns 201 glossary

Plain-language definitions for Design Patterns 201 (Hero to Super Hero). Lesson links point to the first introduction. Terms from level 101 (SOLID, coupling, composition, interface) are in [GLOSSARY.md](GLOSSARY.md).

| Term | Meaning | Lesson |
|---|---|---|
| Design pattern | A named, proven shape for a problem that keeps coming back; a starting design, not a law. | [01](201-hero-to-super-hero/phase-1-creational/01-factory-method-and-abstract-factory.md) |
| Creational / structural / behavioral | The three pattern families: creating objects; assembling objects into structures; sharing work and communication between objects. | [01](201-hero-to-super-hero/phase-1-creational/01-factory-method-and-abstract-factory.md) |
| Factory Method | A method that creates an object and that subclasses override to choose which class is created. | [01](201-hero-to-super-hero/phase-1-creational/01-factory-method-and-abstract-factory.md) |
| Product / creator | The object a factory makes / the class that has the factory method. | [01](201-hero-to-super-hero/phase-1-creational/01-factory-method-and-abstract-factory.md) |
| Abstract Factory | An object with several `create` methods that makes a whole family of matching products. | [01](201-hero-to-super-hero/phase-1-creational/01-factory-method-and-abstract-factory.md) |
| Simple factory | A function or dictionary that picks a class; useful, but not one of the 22 catalogue patterns. | [01](201-hero-to-super-hero/phase-1-creational/01-factory-method-and-abstract-factory.md) |
| Namespace (C#) per pattern | Each pattern file has its own namespace so class names such as `Demo` do not clash. | [01](201-hero-to-super-hero/phase-1-creational/01-factory-method-and-abstract-factory.md) |
| Builder | A separate object that assembles a complex object step by step and validates it in `build()`. | [02](201-hero-to-super-hero/phase-1-creational/02-builder-and-prototype.md) |
| Director | An optional class that holds named recipes (step sequences) for a builder. | [02](201-hero-to-super-hero/phase-1-creational/02-builder-and-prototype.md) |
| Telescoping constructor | A constructor with many positional, mostly optional arguments that is hard to read and call. | [02](201-hero-to-super-hero/phase-1-creational/02-builder-and-prototype.md) |
| Fluent interface | A style where each method returns the object so calls chain (`a.b().c()`); a style, not a pattern. | [02](201-hero-to-super-hero/phase-1-creational/02-builder-and-prototype.md) |
| Prototype | Creating a new object by copying an existing one that knows how to clone itself. | [02](201-hero-to-super-hero/phase-1-creational/02-builder-and-prototype.md) |
| Shallow copy / deep copy | A copy that shares inner objects with the original / a copy that also copies the inner objects. | [02](201-hero-to-super-hero/phase-1-creational/02-builder-and-prototype.md) |
| Registry (of prototypes) | A dictionary of configured template objects that are cloned on demand. | [02](201-hero-to-super-hero/phase-1-creational/02-builder-and-prototype.md) |
| Singleton | A class with exactly one instance and a global access point; usually a design smell. | [03](201-hero-to-super-hero/phase-1-creational/03-singleton-and-dependency-injection.md) |
| Global state | Data that any code can read and change, so bugs show up far from their cause. | [03](201-hero-to-super-hero/phase-1-creational/03-singleton-and-dependency-injection.md) |
| Hidden dependency | A dependency that does not appear in the signature of the function or constructor that uses it. | [03](201-hero-to-super-hero/phase-1-creational/03-singleton-and-dependency-injection.md) |
| Lifetime (singleton, scoped, transient) | How long a DI container keeps a service: one per application, one per request, or a new one each time. | [03](201-hero-to-super-hero/phase-1-creational/03-singleton-and-dependency-injection.md) |
| Lazy (`Lazy<T>`) | A value created on first use; `Lazy<T>` in C# is thread-safe by default. | [03](201-hero-to-super-hero/phase-1-creational/03-singleton-and-dependency-injection.md) |
| Adapter | A wrapper that implements the interface a client expects and translates calls to an incompatible class. | [04](201-hero-to-super-hero/phase-2-structural/04-adapter-and-facade.md) |
| Target / adaptee | The interface the client wants / the existing class with the wrong interface. | [04](201-hero-to-super-hero/phase-2-structural/04-adapter-and-facade.md) |
| Object adapter / class adapter | An adapter that holds the adaptee / one that inherits from it. | [04](201-hero-to-super-hero/phase-2-structural/04-adapter-and-facade.md) |
| Facade | One simple class in front of a group of classes; it does not forbid using the subsystem directly. | [04](201-hero-to-super-hero/phase-2-structural/04-adapter-and-facade.md) |
| Subsystem | The group of classes a facade hides. | [04](201-hero-to-super-hero/phase-2-structural/04-adapter-and-facade.md) |
| God object | A class that has accumulated all the logic of an application. | [04](201-hero-to-super-hero/phase-2-structural/04-adapter-and-facade.md) |
| Decorator | A wrapper with the same interface as the wrapped object that adds behavior around the call. | [05](201-hero-to-super-hero/phase-2-structural/05-decorator-and-proxy.md) |
| Class explosion | A subclass for every combination of features, so the class count multiplies. | [05](201-hero-to-super-hero/phase-2-structural/05-decorator-and-proxy.md) |
| Proxy | A stand-in with the same interface that controls access to the real object (cache, guard, lazy, remote). | [05](201-hero-to-super-hero/phase-2-structural/05-decorator-and-proxy.md) |
| Caching proxy / protection proxy | A proxy that remembers results / one that checks permission before forwarding. | [05](201-hero-to-super-hero/phase-2-structural/05-decorator-and-proxy.md) |
| Composite | A tree where single objects (leaves) and groups share one interface. | [06](201-hero-to-super-hero/phase-2-structural/06-composite-and-flyweight.md) |
| Component / leaf / composite | The shared interface / a node that does the work / a node that holds children. | [06](201-hero-to-super-hero/phase-2-structural/06-composite-and-flyweight.md) |
| Recursion | A method that calls itself on the children to handle a tree of any depth. | [06](201-hero-to-super-hero/phase-2-structural/06-composite-and-flyweight.md) |
| Flyweight | A shared, immutable object that holds the part of the state that many objects have in common. | [06](201-hero-to-super-hero/phase-2-structural/06-composite-and-flyweight.md) |
| Intrinsic / extrinsic state | The shared immutable part / the per-object part that stays outside the flyweight. | [06](201-hero-to-super-hero/phase-2-structural/06-composite-and-flyweight.md) |
| Bridge | Splitting a class that varies in two dimensions into an abstraction hierarchy and an implementation hierarchy joined by one reference. | [07](201-hero-to-super-hero/phase-2-structural/07-bridge.md) |
| Abstraction / implementation (in Bridge) | The high-level control layer / the low-level layer that does the work; not the same as "interface" and "class". | [07](201-hero-to-super-hero/phase-2-structural/07-bridge.md) |
| Strategy | A family of interchangeable algorithms, each in its own class, chosen from outside. | [08](201-hero-to-super-hero/phase-3-behavioral/08-strategy-and-state.md) |
| Context | The class that holds and uses a strategy or a state. | [08](201-hero-to-super-hero/phase-3-behavioral/08-strategy-and-state.md) |
| State (pattern) | Letting an object change behavior by delegating to a state object that owns the transitions. | [08](201-hero-to-super-hero/phase-3-behavioral/08-strategy-and-state.md) |
| Transition | A move from one state to another, triggered by an action. | [08](201-hero-to-super-hero/phase-3-behavioral/08-strategy-and-state.md) |
| Observer | A subject that notifies any number of subscribers without knowing who they are. | [09](201-hero-to-super-hero/phase-3-behavioral/09-observer-and-mediator.md) |
| Subject / observer (subscriber) | The object that changes and keeps the list / an object that is told about the change. | [09](201-hero-to-super-hero/phase-3-behavioral/09-observer-and-mediator.md) |
| Push / pull notification | The subject sends the data / the subject says "changed" and the observer reads what it needs. | [09](201-hero-to-super-hero/phase-3-behavioral/09-observer-and-mediator.md) |
| Event (C#) | A language feature that implements Observer: subscribe with `+=`, unsubscribe with `-=`. | [09](201-hero-to-super-hero/phase-3-behavioral/09-observer-and-mediator.md) |
| Mediator | One object through which peers communicate, so they never refer to each other. | [09](201-hero-to-super-hero/phase-3-behavioral/09-observer-and-mediator.md) |
| Command | A request turned into an object that can be stored, queued, logged and undone. | [10](201-hero-to-super-hero/phase-3-behavioral/10-command-and-memento.md) |
| Receiver / invoker | The object that does the real work / the object that runs and keeps commands. | [10](201-hero-to-super-hero/phase-3-behavioral/10-command-and-memento.md) |
| Undo stack (history) | A last-in, first-out list of executed commands. | [10](201-hero-to-super-hero/phase-3-behavioral/10-command-and-memento.md) |
| Memento | An immutable snapshot of an object's state, created and restored by the object itself. | [10](201-hero-to-super-hero/phase-3-behavioral/10-command-and-memento.md) |
| Originator / caretaker | The object that creates and restores snapshots / the code that stores them without opening them. | [10](201-hero-to-super-hero/phase-3-behavioral/10-command-and-memento.md) |
| Iterator | An object that walks a collection and remembers its own position. | [11](201-hero-to-super-hero/phase-3-behavioral/11-iterator-template-method-visitor-chain.md) |
| Generator (`yield`) | A function that produces items one at a time, pausing between them. | [11](201-hero-to-super-hero/phase-3-behavioral/11-iterator-template-method-visitor-chain.md) |
| Lazy evaluation | Producing a value only when it is asked for. | [11](201-hero-to-super-hero/phase-3-behavioral/11-iterator-template-method-visitor-chain.md) |
| Template Method | A base-class method that fixes the order of steps while subclasses supply some of the steps. | [11](201-hero-to-super-hero/phase-3-behavioral/11-iterator-template-method-visitor-chain.md) |
| Hook | A step with a default implementation that a subclass may override. | [11](201-hero-to-super-hero/phase-3-behavioral/11-iterator-template-method-visitor-chain.md) |
| Visitor | An object with one method per class of a family that adds an operation without editing those classes. | [11](201-hero-to-super-hero/phase-3-behavioral/11-iterator-template-method-visitor-chain.md) |
| Double dispatch | Choosing the method by the types of two objects (the element and the visitor) with no `if`. | [11](201-hero-to-super-hero/phase-3-behavioral/11-iterator-template-method-visitor-chain.md) |
| Expression problem | The trade-off that new operations are cheap with a visitor but new classes are expensive. | [11](201-hero-to-super-hero/phase-3-behavioral/11-iterator-template-method-visitor-chain.md) |
| Chain of Responsibility | A request passes along handlers; each handles it or passes it on. | [11](201-hero-to-super-hero/phase-3-behavioral/11-iterator-template-method-visitor-chain.md) |
| Middleware | A pipeline of handlers around a request, as in web frameworks. | [11](201-hero-to-super-hero/phase-3-behavioral/11-iterator-template-method-visitor-chain.md) |
| Pattern fever (golden hammer) | Using patterns because you know them, not because a pain needs them. | [12](201-hero-to-super-hero/phase-4-choosing-patterns/12-choosing-combining-refactoring.md) |
| Speculative generality | Abstractions built for a future that has not arrived (a YAGNI violation). | [12](201-hero-to-super-hero/phase-4-choosing-patterns/12-choosing-combining-refactoring.md) |
| Anti-pattern | A common, tempting solution that causes more problems than it solves. | [12](201-hero-to-super-hero/phase-4-choosing-patterns/12-choosing-combining-refactoring.md) |
| Smell | A sign in the code that points to a design problem (from level 101); the starting point for choosing a pattern. | [12](201-hero-to-super-hero/phase-4-choosing-patterns/12-choosing-combining-refactoring.md) |
| Refactoring toward patterns | Reaching a pattern through small, behavior-preserving steps from a concrete pain. | [12](201-hero-to-super-hero/phase-4-choosing-patterns/12-choosing-combining-refactoring.md) |
| Safety net | A check (here: old and new versions give the same output) that proves a refactoring did not change behavior. | [12](201-hero-to-super-hero/phase-4-choosing-patterns/12-choosing-combining-refactoring.md) |
