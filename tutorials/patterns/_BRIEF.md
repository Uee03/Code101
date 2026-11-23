# Design Patterns + SOLID 101 (Zero to Hero): author brief

## Learner and outcome
Learners who finished Python 101 and/or C# 101 (functions, lists, dictionaries, classes and objects). Nine lessons in two downloadable phases teach the principles that make code easy to change: coupling and cohesion, the five SOLID principles, DRY/KISS/YAGNI, composition over inheritance and reading class diagrams. Every example exists in **Python and C#** (the learner follows one and compares with the other). The lessons start with an everyday analogy, show the **bad design first**, refactor it, and include a Mermaid class diagram, a predict-before-run step, a three-rung exercise (guided, change, stretch) and a small hand-made check instead of a test framework.
Time: 35 to 45 minutes per lesson for one language (add about 20 minutes for both); lesson 09 about 60 minutes in two sittings.
Level 101 does not name individual design patterns except to say where a technique has a name (Strategy, Bridge, Decorator); the full catalogue is level 201.

## Version decision (2026-11-23)
- Python 3.10 or newer (type hints in `after.py`; f-strings; `abc`). No packages.
- .NET SDK 11 with `net11.0`, `ImplicitUsings` and `Nullable` enabled, one minimal `Lesson.csproj` shown in full in every lesson. Top-level statements in `Program.cs`; tuple type alias `using Item = (string Name, int PriceCents, int Quantity);`; file-scoped namespaces `Before` and `After` so both designs live in one project. No `global.json`, no packages.
- Money is whole cents (`int`) so there are no rounding surprises and the output is identical in both languages.

## Lesson map
| Phase | Lesson | Main build / exercise |
|---|---|---|
| 1 solid | 01 Why design matters | one long invoice function vs small functions; coupling, cohesion, smells / shipping summary |
| 1 solid | 02 Single Responsibility | `Invoice` split into formatter, store, sender / order receipt and SMS |
| 1 solid | 03 Open/Closed | discount `if` chain vs rule classes, new rule in a new file / shipping rules |
| 1 solid | 04 Liskov Substitution | `PaymentMethod` with a gift card that cannot refund, split into `Payable` and `Refundable` / report channels |
| 1 solid | 05 Interface Segregation | fat `Notifier` with empty stubs vs `EmailSender`, `SmsSender`, `PushSender` / price catalog |
| 1 solid | 06 Dependency Inversion and injection by hand | `OrderService` building its own sender vs constructor injection and a fake; SOLID mixed review / clock |
| 2 everyday-principles | 07 DRY, KISS, YAGNI | duplicated rule, clever one-liner, unused extras; when DRY is wrong / greetings clean-up |
| 2 everyday-principles | 08 Composition over inheritance | notifier class tree vs channel and tone parts / shipping carrier and speed |
| 2 everyday-principles | 09 Reading and drawing class diagrams, and a mixed review | Mermaid notation, read and draw, refactor a messy `OrderProcessor` / booking manager |

Each lesson uses the shop domain (orders, invoices, notifications) so learners meet the same vocabulary, and reuses the helper idea "items are `(name, price in cents, quantity)`".

## Sources (Tier 2, paraphrased, never copied)
- Design patterns catalogue and code smells: https://refactoring.guru/design-patterns/catalog and https://refactoring.guru/refactoring/smells
- Cross-check: https://sourcemaking.com/design_patterns and https://sourcemaking.com/refactoring/smells
- SOLID: https://www.digitalocean.com/community/conceptual-articles/s-o-l-i-d-the-first-five-principles-of-object-oriented-design
- SOLID in Python (Real Python) was not cited: the site blocks scripted link checks (403); used only as background reading
- Mermaid class diagrams (Tier 1): https://mermaid.js.org/syntax/classDiagram.html
- Python `abc` and typing (Tier 1): https://docs.python.org/3/library/abc.html and https://docs.python.org/3/library/typing.html
- C# interfaces (Tier 1): https://learn.microsoft.com/dotnet/csharp/fundamentals/types/interfaces
- YAGNI: https://martinfowler.com/bliki/Yagni.html

## Delivery and verification (policy of 2026-11-23: no smoke tests)
- Only author `tutorials/patterns/` and `source/patterns/101-zero-to-hero/`. No art (`assets: []`).
- The code was **not executed**. Every lesson carries the verbatim "Draft: written but not yet run" notice directly under the H1 and `verified: not yet run` in its front matter. Expected output was derived by reading the code. Common-mistakes tables say "typical messages, not yet reproduced".
- Allowed checks: `python scripts/verify_labs.py --static patterns/101-zero-to-hero` (executes nothing) and `python scripts/build_packs.py patterns-101`.
- Later: run `python scripts/verify_labs.py source/patterns/` once Python and .NET are available, fix any difference between text and real output, remove the draft notice and set `verified:` to the real date.
- Level 201 (the 22-pattern catalogue) is written in separate files by another author; do not edit them from here.
