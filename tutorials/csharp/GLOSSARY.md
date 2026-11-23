# C# glossary

Plain-language definitions for C# 101. Lesson links point to the first introduction (or the fuller treatment where noted). Symbols keep their C# meaning even when English output uses different capitalization.

| Term | Meaning | Lesson |
|---|---|---|
| Program | Instructions a computer follows. | [01](101-zero-to-hero/phase-1-foundations/01-hello-csharp.md) |
| C# | The programming language used in this track, pronounced C sharp. | [01](101-zero-to-hero/phase-1-foundations/01-hello-csharp.md) |
| .NET | The platform providing our build tools, runtime and standard library. | [01](101-zero-to-hero/phase-1-foundations/01-hello-csharp.md) |
| Console application | A program using text input and output in a terminal. | [01](101-zero-to-hero/phase-1-foundations/01-hello-csharp.md) |
| Terminal | A window for typing commands and seeing text replies. | [01](101-zero-to-hero/phase-1-foundations/01-hello-csharp.md) |
| Prompt | The terminal marker before your command; do not type it. | [01](101-zero-to-hero/phase-1-foundations/01-hello-csharp.md) |
| Command | An instruction submitted to the terminal with Enter. | [01](101-zero-to-hero/phase-1-foundations/01-hello-csharp.md) |
| Current folder / working directory | The folder from which relative paths are resolved. | [01](101-zero-to-hero/phase-1-foundations/01-hello-csharp.md) |
| SDK | Software development kit: tools for building apps, including the runtime. | [01](101-zero-to-hero/phase-1-foundations/01-hello-csharp.md) |
| Runtime | Software that executes built .NET applications. | [01](101-zero-to-hero/phase-1-foundations/01-hello-csharp.md) |
| PATH | The list of folders searched for commands. | [01](101-zero-to-hero/phase-1-foundations/01-hello-csharp.md) |
| STS | Standard-term support, the supported release category chosen here. | [01](101-zero-to-hero/phase-1-foundations/01-hello-csharp.md) |
| Editor | A tool for editing plain-text source files. | [01](101-zero-to-hero/phase-1-foundations/01-hello-csharp.md) |
| Extension | An editor add-on, such as C# Dev Kit. | [01](101-zero-to-hero/phase-1-foundations/01-hello-csharp.md) |
| Source file | The editable instructions, such as Program.cs. | [01](101-zero-to-hero/phase-1-foundations/01-hello-csharp.md) |
| Project manifest | The .csproj file describing build settings. | [01](101-zero-to-hero/phase-1-foundations/01-hello-csharp.md) |
| XML | Extensible Markup Language; settings structured with named tags. | [01](101-zero-to-hero/phase-1-foundations/01-hello-csharp.md) |
| JSON | A structured data format using named entries, values, braces and commas. | [01](101-zero-to-hero/phase-1-foundations/01-hello-csharp.md) |
| Target framework | The .NET API/runtime version selected by TargetFramework, net11.0 here. | [01](101-zero-to-hero/phase-1-foundations/01-hello-csharp.md) |
| SDK pin | A global.json setting selecting which SDK builds a project. | [01](101-zero-to-hero/phase-1-foundations/01-hello-csharp.md) |
| Servicing patch | An update within the selected SDK/runtime release line. | [01](101-zero-to-hero/phase-1-foundations/01-hello-csharp.md) |
| Restore | Preparing the dependencies and framework information needed to build. | [01](101-zero-to-hero/phase-1-foundations/01-hello-csharp.md) |
| Build | Translating source into compiled program files. | [01](101-zero-to-hero/phase-1-foundations/01-hello-csharp.md) |
| Compiler | The translator from C# source into runnable instructions. | [01](101-zero-to-hero/phase-1-foundations/01-hello-csharp.md) |
| Entry point | The place where program execution begins. | [01](101-zero-to-hero/phase-1-foundations/01-hello-csharp.md) |
| Top-level statements | Entry instructions written without an explicit surrounding Main method. | [01](101-zero-to-hero/phase-1-foundations/01-hello-csharp.md) |
| Type | A description of what a value is or which operations it supports. | [01](101-zero-to-hero/phase-1-foundations/01-hello-csharp.md) |
| Method | A named operation that can receive inputs and optionally return a value. | [01](101-zero-to-hero/phase-1-foundations/01-hello-csharp.md) |
| String | A sequence of characters, written in double quotes. | [01](101-zero-to-hero/phase-1-foundations/01-hello-csharp.md) |
| Statement | One instruction, often ended by a semicolon. | [01](101-zero-to-hero/phase-1-foundations/01-hello-csharp.md) |
| Comment | A note ignored by the compiler; // starts a line comment. | [01](101-zero-to-hero/phase-1-foundations/01-hello-csharp.md) |
| Source pack | A downloadable zip containing runnable examples and exercises. | [01](101-zero-to-hero/phase-1-foundations/01-hello-csharp.md) |
| Variable | A named place for a value. | [02](101-zero-to-hero/phase-1-foundations/02-variables-and-types.md) |
| Declaration | Introducing a variable with a type and name. | [02](101-zero-to-hero/phase-1-foundations/02-variables-and-types.md) |
| Initialization | Giving a variable its first value. | [02](101-zero-to-hero/phase-1-foundations/02-variables-and-types.md) |
| Assignment | Storing a value with =. | [02](101-zero-to-hero/phase-1-foundations/02-variables-and-types.md) |
| int | A whole-number type ranging from -2147483648 to 2147483647. | [02](101-zero-to-hero/phase-1-foundations/02-variables-and-types.md) |
| double | An approximate binary fractional-number type. | [02](101-zero-to-hero/phase-1-foundations/02-variables-and-types.md) |
| decimal | A base-ten decimal numeric type, useful for money-like calculations. | [02](101-zero-to-hero/phase-1-foundations/02-variables-and-types.md) |
| bool / boolean | A type with values true or false. | [02](101-zero-to-hero/phase-1-foundations/02-variables-and-types.md) |
| var / type inference | Letting the compiler infer a variable type from its initial value. | [02](101-zero-to-hero/phase-1-foundations/02-variables-and-types.md) |
| Literal | A value written directly in source code. | [02](101-zero-to-hero/phase-1-foundations/02-variables-and-types.md) |
| Namespace | A named grouping of related types. | [02](101-zero-to-hero/phase-1-foundations/02-variables-and-types.md) |
| Culture | Regional text and number conventions. | [02](101-zero-to-hero/phase-1-foundations/02-variables-and-types.md) |
| Invariant culture | A stable set of culture-independent formatting conventions, including a decimal dot. | [02](101-zero-to-hero/phase-1-foundations/02-variables-and-types.md) |
| String interpolation | Inserting values into text with a dollar-prefixed string and braces. | [02](101-zero-to-hero/phase-1-foundations/02-variables-and-types.md) |
| Format specifier | An instruction for displaying a value; F2 displays two fractional digits. | [02](101-zero-to-hero/phase-1-foundations/02-variables-and-types.md) |
| Operator | A symbol performing an operation such as addition or comparison. | [03](101-zero-to-hero/phase-1-foundations/03-input-and-math.md) |
| Expression | Code that evaluates to a value. | [03](101-zero-to-hero/phase-1-foundations/03-input-and-math.md) |
| Integer division | Division of integer operands, discarding the fractional part. | [03](101-zero-to-hero/phase-1-foundations/03-input-and-math.md) |
| Remainder | What is left after integer division; computed with %. | [03](101-zero-to-hero/phase-1-foundations/03-input-and-math.md) |
| Parsing | Converting text into a typed value. | [03](101-zero-to-hero/phase-1-foundations/03-input-and-math.md) |
| Nested call | A method call used inside another call; the inner call supplies an argument. | [03](101-zero-to-hero/phase-1-foundations/03-input-and-math.md) |
| TryParse | A conversion method returning success/failure and supplying a parsed out value. | [03](101-zero-to-hero/phase-1-foundations/03-input-and-math.md) |
| out | A parameter modifier allowing a method to supply a value to the caller. | [03](101-zero-to-hero/phase-1-foundations/03-input-and-math.md) |
| null | The absence of a value, distinct from an empty string. | [03](101-zero-to-hero/phase-1-foundations/03-input-and-math.md) |
| Null-coalescing operator (??) | Choose the left value if non-null; otherwise use the right fallback. | [03](101-zero-to-hero/phase-1-foundations/03-input-and-math.md) |
| Exception | A runtime failure signal that can be caught by a matching handler. | [03](101-zero-to-hero/phase-1-foundations/03-input-and-math.md) |
| FormatException | An exception for text not matching the required format. | [03](101-zero-to-hero/phase-1-foundations/03-input-and-math.md) |
| OverflowException | An exception when a conversion or checked operation exceeds its numeric range. | [03](101-zero-to-hero/phase-1-foundations/03-input-and-math.md) |
| Comparison | A yes/no question about values, such as age < 5. | [04](101-zero-to-hero/phase-1-foundations/04-making-decisions.md) |
| Boolean expression | An expression evaluating to true or false. | [04](101-zero-to-hero/phase-1-foundations/04-making-decisions.md) |
| Condition | A boolean expression deciding whether work should happen. | [04](101-zero-to-hero/phase-1-foundations/04-making-decisions.md) |
| Branch | One possible path through a selection. | [04](101-zero-to-hero/phase-1-foundations/04-making-decisions.md) |
| if/else chain | A selection using only the first matching branch. | [04](101-zero-to-hero/phase-1-foundations/04-making-decisions.md) |
| Block | Statements grouped inside braces. | [04](101-zero-to-hero/phase-1-foundations/04-making-decisions.md) |
| Indentation | Leading spaces making nested structure readable. | [04](101-zero-to-hero/phase-1-foundations/04-making-decisions.md) |
| Short-circuit evaluation | Skipping the right side of && or &#124;&#124; when the left already determines the result. | [04](101-zero-to-hero/phase-1-foundations/04-making-decisions.md) |
| Switch expression | A value-producing selection with matching arms. | [04](101-zero-to-hero/phase-1-foundations/04-making-decisions.md) |
| Pattern | A description of values to match; the first example uses true and false. | [04](101-zero-to-hero/phase-1-foundations/04-making-decisions.md) |
| Logical operators | && (both), &#124;&#124; (at least one), and ! (negation). | [04](101-zero-to-hero/phase-1-foundations/04-making-decisions.md) |
| Loop | A block repeated according to a rule. | [05](101-zero-to-hero/phase-2-building-blocks/05-loops.md) |
| Iteration | One pass through a loop body. | [05](101-zero-to-hero/phase-2-building-blocks/05-loops.md) |
| for | A loop combining initialization, condition and update. | [05](101-zero-to-hero/phase-2-building-blocks/05-loops.md) |
| foreach | A loop visiting each element in a sequence. | [05](101-zero-to-hero/phase-2-building-blocks/05-loops.md) |
| while | A loop repeating while a condition is true. | [05](101-zero-to-hero/phase-2-building-blocks/05-loops.md) |
| char | A single-character value, normally written in single quotes. | [05](101-zero-to-hero/phase-2-building-blocks/05-loops.md) |
| Increment / decrement | Increase / decrease a value by one using ++ / --. | [05](101-zero-to-hero/phase-2-building-blocks/05-loops.md) |
| continue | Skip the rest of the current loop iteration. | [05](101-zero-to-hero/phase-2-building-blocks/05-loops.md) |
| break | Exit the nearest loop or switch statement. | [05](101-zero-to-hero/phase-2-building-blocks/05-loops.md) |
| Infinite loop | A loop whose stopping condition is never reached. | [05](101-zero-to-hero/phase-2-building-blocks/05-loops.md) |
| Parameter | A named input in a method definition. | [06](101-zero-to-hero/phase-2-building-blocks/06-methods.md) |
| Argument | A particular value passed at a call. | [06](101-zero-to-hero/phase-2-building-blocks/06-methods.md) |
| Call | Starting a method with specified arguments. | [06](101-zero-to-hero/phase-2-building-blocks/06-methods.md) |
| Return value | A value handed back from a method to its caller. | [06](101-zero-to-hero/phase-2-building-blocks/06-methods.md) |
| void | A return type meaning that no value is returned. | [06](101-zero-to-hero/phase-2-building-blocks/06-methods.md) |
| Scope | The region where a name can be used. | [06](101-zero-to-hero/phase-2-building-blocks/06-methods.md) |
| Local variable | A variable whose name is usable only inside its block or method. | [06](101-zero-to-hero/phase-2-building-blocks/06-methods.md) |
| Collection | A grouping of values. | [07](101-zero-to-hero/phase-2-building-blocks/07-arrays-lists-and-dictionaries.md) |
| Array | A fixed-length indexed sequence. | [07](101-zero-to-hero/phase-2-building-blocks/07-arrays-lists-and-dictionaries.md) |
| Index | An element position; C# sequences start at zero. | [07](101-zero-to-hero/phase-2-building-blocks/07-arrays-lists-and-dictionaries.md) |
| List | A sequence whose element count can grow or shrink. | [07](101-zero-to-hero/phase-2-building-blocks/07-arrays-lists-and-dictionaries.md) |
| Dictionary | A collection mapping unique keys to values. | [07](101-zero-to-hero/phase-2-building-blocks/07-arrays-lists-and-dictionaries.md) |
| Key | The value used to locate a dictionary entry. | [07](101-zero-to-hero/phase-2-building-blocks/07-arrays-lists-and-dictionaries.md) |
| Generic type | A type design parameterized by specified element or key/value types. | [07](101-zero-to-hero/phase-2-building-blocks/07-arrays-lists-and-dictionaries.md) |
| Constructor | An operation called with new that creates and initializes a ready-to-use value. | [07](101-zero-to-hero/phase-2-building-blocks/07-arrays-lists-and-dictionaries.md) |
| TryGetValue | A safe dictionary lookup returning success and an out value. | [07](101-zero-to-hero/phase-2-building-blocks/07-arrays-lists-and-dictionaries.md) |
| Path | A file or folder location. | [08](101-zero-to-hero/phase-2-building-blocks/08-files.md) |
| Relative path | A location resolved from the working directory. | [08](101-zero-to-hero/phase-2-building-blocks/08-files.md) |
| Absolute path | A full location independent of the working directory. | [08](101-zero-to-hero/phase-2-building-blocks/08-files.md) |
| CSV | Comma-separated values; this track uses a deliberately restricted unquoted format. | [08](101-zero-to-hero/phase-2-building-blocks/08-files.md) |
| Header | The first CSV row naming the columns. | [08](101-zero-to-hero/phase-2-building-blocks/08-files.md) |
| Delimiter | A character separating fields or rows. | [08](101-zero-to-hero/phase-2-building-blocks/08-files.md) |
| Escape sequence | A backslash notation for a character, such as backslash-n for newline. | [08](101-zero-to-hero/phase-2-building-blocks/08-files.md) |
| Enum | A type defining named choices. | [08](101-zero-to-hero/phase-2-building-blocks/08-files.md) |
| Persistence | Keeping data after a program exits, for example in a file. | [08](101-zero-to-hero/phase-2-building-blocks/08-files.md) |
| try block | Work whose exceptions can be handled by attached catches. | [09](101-zero-to-hero/phase-3-real-programs/09-handling-errors.md) |
| catch block | A handler for a matching exception. | [09](101-zero-to-hero/phase-3-real-programs/09-handling-errors.md) |
| finally block | Work run when control leaves try/catch, on success or failure. | [09](101-zero-to-hero/phase-3-real-programs/09-handling-errors.md) |
| End of input | No more characters available; ReadLine returns null. | [09](101-zero-to-hero/phase-3-real-programs/09-handling-errors.md) |
| Nullable string (string?) | A string annotation permitting a missing value. | [09](101-zero-to-hero/phase-3-real-programs/09-handling-errors.md) |
| Class | A blueprint for objects with state and behaviour. | [10](101-zero-to-hero/phase-3-real-programs/10-classes-and-objects.md) |
| Object / instance | One particular value created from a class. | [10](101-zero-to-hero/phase-3-real-programs/10-classes-and-objects.md) |
| Field | A value stored as part of an object. | [10](101-zero-to-hero/phase-3-real-programs/10-classes-and-objects.md) |
| Property | A member exposing information through accessors. | [10](101-zero-to-hero/phase-3-real-programs/10-classes-and-objects.md) |
| Auto-property | A property whose backing storage is supplied by the compiler. | [10](101-zero-to-hero/phase-3-real-programs/10-classes-and-objects.md) |
| Getter | The accessor that reads a property. | [10](101-zero-to-hero/phase-3-real-programs/10-classes-and-objects.md) |
| Computed property | A property deriving its value from an expression or code. | [10](101-zero-to-hero/phase-3-real-programs/10-classes-and-objects.md) |
| Instance method | A method operating on a particular object. | [10](101-zero-to-hero/phase-3-real-programs/10-classes-and-objects.md) |
| public | Accessible by other code. | [10](101-zero-to-hero/phase-3-real-programs/10-classes-and-objects.md) |
| private | Accessible only within the declaring type. | [10](101-zero-to-hero/phase-3-real-programs/10-classes-and-objects.md) |
| Encapsulation | Keeping object state and its update rules together. | [10](101-zero-to-hero/phase-3-real-programs/10-classes-and-objects.md) |
| Reference type | A type whose variables hold references to objects; class and record class are examples. | [11](101-zero-to-hero/phase-3-real-programs/11-null-safety-and-records.md) |
| Nullable reference type | An annotation allowing null, checked by compiler analysis. | [11](101-zero-to-hero/phase-3-real-programs/11-null-safety-and-records.md) |
| Null-conditional operator (?.) | Access a member only if its receiver is non-null; otherwise yield null. | [11](101-zero-to-hero/phase-3-real-programs/11-null-safety-and-records.md) |
| Record | A data-focused type with a supplied constructor, properties, value equality and copying behaviour. | [11](101-zero-to-hero/phase-3-real-programs/11-null-safety-and-records.md) |
| Value equality | Comparing corresponding values rather than requiring the same object identity. | [11](101-zero-to-hero/phase-3-real-programs/11-null-safety-and-records.md) |
| Non-destructive copy | A copy with selected changes that leaves the original unchanged. | [11](101-zero-to-hero/phase-3-real-programs/11-null-safety-and-records.md) |
| Switch statement | A statement selection using case, break and default. | [12](101-zero-to-hero/phase-3-real-programs/12-expense-tracker.md) |
| Overload | A same-named method with a different parameter list. | [12](101-zero-to-hero/phase-3-real-programs/12-expense-tracker.md) |
| I/O | Input/output, including file reads and writes. | [12](101-zero-to-hero/phase-3-real-programs/12-expense-tracker.md) |
| Validation | Checking that data satisfies rules before using or storing it. | [12](101-zero-to-hero/phase-3-real-programs/12-expense-tracker.md) |
| Self-check | A small internal check of an expected behaviour. | [12](101-zero-to-hero/phase-3-real-programs/12-expense-tracker.md) |
| Assertion | A condition that fails visibly if false. | [12](101-zero-to-hero/phase-3-real-programs/12-expense-tracker.md) |
| Round trip | Converting a value to another representation and back. | [12](101-zero-to-hero/phase-3-real-programs/12-expense-tracker.md) |
| Accumulator | A variable updated repeatedly to collect a total. | [12](101-zero-to-hero/phase-3-real-programs/12-expense-tracker.md) |
| Serialization | Converting values into a stored text form, CSV here. | [12](101-zero-to-hero/phase-3-real-programs/12-expense-tracker.md) |
| throw | Explicitly signal an exception. | [12](101-zero-to-hero/phase-3-real-programs/12-expense-tracker.md) |
| IOException | An exception reporting an input/output failure. | [12](101-zero-to-hero/phase-3-real-programs/12-expense-tracker.md) |
| UnauthorizedAccessException | An exception reporting a denied file or folder operation. | [12](101-zero-to-hero/phase-3-real-programs/12-expense-tracker.md) |
| Sequence | An ordered series of values. | [01](101-zero-to-hero/phase-1-foundations/01-hello-csharp.md) |
| Feature band | An SDK update family such as 11.0.1xx, beginning at 11.0.100. | [01](101-zero-to-hero/phase-1-foundations/01-hello-csharp.md) |
| Telemetry | Collection of tool-usage data; the CLI offers an opt-out environment variable. | [01](101-zero-to-hero/phase-1-foundations/01-hello-csharp.md) |
| Warning | A compiler diagnostic that allows the build to continue but flags something to check. | [01](101-zero-to-hero/phase-1-foundations/01-hello-csharp.md) |
| Error | A compiler diagnostic that prevents a successful build. | [01](101-zero-to-hero/phase-1-foundations/01-hello-csharp.md) |
| Stack trace | Lines naming the chain of calls that led to an exception; read the exception message first. | [01](101-zero-to-hero/phase-1-foundations/01-hello-csharp.md) |
| Arm | One pattern/result pair in a switch expression. | [04](101-zero-to-hero/phase-1-foundations/04-making-decisions.md) |
| Body | The block of instructions a loop or method executes. | [05](101-zero-to-hero/phase-2-building-blocks/05-loops.md) |
| Off-by-one mistake | A boundary error that runs one iteration too many or too few. | [05](101-zero-to-hero/phase-2-building-blocks/05-loops.md) |
| Caller | The code that starts a method call and receives any returned value. | [06](101-zero-to-hero/phase-2-building-blocks/06-methods.md) |
| State | The current information stored by an object. | [10](101-zero-to-hero/phase-3-real-programs/10-classes-and-objects.md) |
| Expression-bodied getter | A property getter written with => followed by the expression it returns. | [10](101-zero-to-hero/phase-3-real-programs/10-classes-and-objects.md) |

## C# 201 terms

Terms first introduced in C# 201 (Hero to Super Hero). Lesson links use the form 201-NN.

| Term | Meaning | Lesson |
|---|---|---|
| Interface | A contract listing members a type must provide, with no required implementation. | [201-01](201-hero-to-super-hero/phase-1-core-skills/01-interfaces-inheritance-polymorphism.md) |
| Abstract class | A class that cannot be created directly and may mix finished code with members subclasses must supply. | [201-01](201-hero-to-super-hero/phase-1-core-skills/01-interfaces-inheritance-polymorphism.md) |
| virtual / override | `virtual` allows a subclass to replace a method; `override` replaces it. | [201-01](201-hero-to-super-hero/phase-1-core-skills/01-interfaces-inheritance-polymorphism.md) |
| Polymorphism | Using one type (an interface or base class) for many real types, each answering in its own way. | [201-01](201-hero-to-super-hero/phase-1-core-skills/01-interfaces-inheritance-polymorphism.md) |
| sealed | A modifier that forbids further inheritance of a class. | [201-01](201-hero-to-super-hero/phase-1-core-skills/01-interfaces-inheritance-polymorphism.md) |
| Composition | Building behaviour by holding another object in a field instead of inheriting from it. | [201-01](201-hero-to-super-hero/phase-1-core-skills/01-interfaces-inheritance-polymorphism.md) |
| Liskov substitution principle | A subtype must work wherever its base type is expected. | [201-01](201-hero-to-super-hero/phase-1-core-skills/01-interfaces-inheritance-polymorphism.md) |
| Primary constructor | Parameters written after a class name (C# 12) that are usable in every member. | [201-01](201-hero-to-super-hero/phase-1-core-skills/01-interfaces-inheritance-polymorphism.md) |
| Generic type | A type or method written with type parameters (`List<T>`) so one definition works for many types. | [201-02](201-hero-to-super-hero/phase-1-core-skills/02-generics-and-collections.md) |
| Constraint | A `where` rule limiting which types may be used for a type parameter. | [201-02](201-hero-to-super-hero/phase-1-core-skills/02-generics-and-collections.md) |
| Covariance | Using `IEnumerable<Derived>` where `IEnumerable<Base>` is expected, because items are only read out. | [201-02](201-hero-to-super-hero/phase-1-core-skills/02-generics-and-collections.md) |
| LINQ | Language Integrated Query: query operators over collections (and, with EF Core, databases). | [201-03](201-hero-to-super-hero/phase-1-core-skills/03-linq.md) |
| Deferred execution | A query is a recipe that runs only when its result is enumerated. | [201-03](201-hero-to-super-hero/phase-1-core-skills/03-linq.md) |
| Anonymous type | A throw-away read-only type created with `new { ... }`. | [201-03](201-hero-to-super-hero/phase-1-core-skills/03-linq.md) |
| Task | An object representing work that will finish later, possibly with a result. | [201-04](201-hero-to-super-hero/phase-1-core-skills/04-async-await-and-task.md) |
| async / await | Keywords that pause a method without blocking its thread until a task finishes. | [201-04](201-hero-to-super-hero/phase-1-core-skills/04-async-await-and-task.md) |
| CancellationToken | A signal passed to long operations so they can stop early. | [201-04](201-hero-to-super-hero/phase-1-core-skills/04-async-await-and-task.md) |
| Thread pool | The shared set of worker threads .NET uses for continuations and `Task.Run`. | [201-04](201-hero-to-super-hero/phase-1-core-skills/04-async-await-and-task.md) |
| Minimal API | Declaring HTTP routes with `MapGet`/`MapPost` and handler methods, without controller classes. | [201-05](201-hero-to-super-hero/phase-2-web-apis/05-first-aspnet-core-api.md) |
| Controller | A class whose attributed methods handle HTTP requests (ASP.NET Core MVC). | [201-05](201-hero-to-super-hero/phase-2-web-apis/05-first-aspnet-core-api.md) |
| REPR pattern | Request, Endpoint, Response: one class per operation with explicit input and output types. | [201-05](201-hero-to-super-hero/phase-2-web-apis/05-first-aspnet-core-api.md) |
| FastEndpoints | A NuGet library that implements the REPR pattern on ASP.NET Core. | [201-05](201-hero-to-super-hero/phase-2-web-apis/05-first-aspnet-core-api.md) |
| Binding | Turning route values, query strings and JSON bodies into C# values. | [201-05](201-hero-to-super-hero/phase-2-web-apis/05-first-aspnet-core-api.md) |
| Kestrel | The web server built into ASP.NET Core. | [201-05](201-hero-to-super-hero/phase-2-web-apis/05-first-aspnet-core-api.md) |
| DTO | Data transfer object: a type that defines what crosses the API boundary. | [201-06](201-hero-to-super-hero/phase-2-web-apis/06-dtos-validation-result-problemdetails.md) |
| Over-posting | A client setting fields it should not by adding them to the request body. | [201-06](201-hero-to-super-hero/phase-2-web-apis/06-dtos-validation-result-problemdetails.md) |
| FluentValidation | A library for writing validation rules as C# classes. | [201-06](201-hero-to-super-hero/phase-2-web-apis/06-dtos-validation-result-problemdetails.md) |
| Result pattern | Returning success or an error as a value instead of throwing for expected failures. | [201-06](201-hero-to-super-hero/phase-2-web-apis/06-dtos-validation-result-problemdetails.md) |
| ProblemDetails | The standard JSON error format (RFC 9457) with `type`, `title`, `status` and `detail`. | [201-06](201-hero-to-super-hero/phase-2-web-apis/06-dtos-validation-result-problemdetails.md) |
| Dependency injection | A container supplies the objects a class asks for in its constructor. | [201-07](201-hero-to-super-hero/phase-2-web-apis/07-dependency-injection-and-options.md) |
| Service lifetime | How long an instance lives: singleton (whole run), scoped (one request), transient (every request for it). | [201-07](201-hero-to-super-hero/phase-2-web-apis/07-dependency-injection-and-options.md) |
| Captive dependency | A longer-lived service holding a shorter-lived one, so the short-lived one never ends. | [201-07](201-hero-to-super-hero/phase-2-web-apis/07-dependency-injection-and-options.md) |
| Options pattern | Binding a configuration section to a validated class injected as `IOptions<T>`. | [201-07](201-hero-to-super-hero/phase-2-web-apis/07-dependency-injection-and-options.md) |
| Configuration provider | A source of settings (JSON file, environment variable, command line); later sources win. | [201-07](201-hero-to-super-hero/phase-2-web-apis/07-dependency-injection-and-options.md) |
| ORM | Object-relational mapper: a library that maps objects to database tables and queries to SQL. | [201-08](201-hero-to-super-hero/phase-3-data/08-ef-core-and-postgres.md) |
| EF Core | Entity Framework Core, Microsoft's ORM for .NET. | [201-08](201-hero-to-super-hero/phase-3-data/08-ef-core-and-postgres.md) |
| DbContext | EF Core's unit of work: a short-lived session with the database and the change tracker. | [201-08](201-hero-to-super-hero/phase-3-data/08-ef-core-and-postgres.md) |
| Entity | A class that EF Core maps to a table. | [201-08](201-hero-to-super-hero/phase-3-data/08-ef-core-and-postgres.md) |
| Navigation property | A property that points to a related entity or collection. | [201-08](201-hero-to-super-hero/phase-3-data/08-ef-core-and-postgres.md) |
| Migration | A versioned, reviewable change to the database schema, generated as code. | [201-08](201-hero-to-super-hero/phase-3-data/08-ef-core-and-postgres.md) |
| Change tracker | EF Core's record of loaded entities and their original values, used by `SaveChanges`. | [201-08](201-hero-to-super-hero/phase-3-data/08-ef-core-and-postgres.md) |
| N+1 problem | One query for a list plus one more for each item. | [201-08](201-hero-to-super-hero/phase-3-data/08-ef-core-and-postgres.md) |
| Docker Compose | A tool that describes and starts several containers from one `docker-compose.yml`. | [201-08](201-hero-to-super-hero/phase-3-data/08-ef-core-and-postgres.md) |
| Volume | Docker-managed storage that survives container removal. | [201-08](201-hero-to-super-hero/phase-3-data/08-ef-core-and-postgres.md) |
| Healthcheck | A command Docker runs to decide whether a container is ready. | [201-08](201-hero-to-super-hero/phase-3-data/08-ef-core-and-postgres.md) |
| Stored function / procedure | Named SQL code stored in the database; a function returns values and a procedure is started with `CALL`. | [201-09](201-hero-to-super-hero/phase-3-data/09-stored-procedures-and-raw-sql.md) |
| Dapper | A micro-ORM: you write SQL and it maps parameters and rows. | [201-09](201-hero-to-super-hero/phase-3-data/09-stored-procedures-and-raw-sql.md) |
| Parameterized query | SQL text and values sent separately, so values can never change the command. | [201-09](201-hero-to-super-hero/phase-3-data/09-stored-procedures-and-raw-sql.md) |
| SQL injection | An attack in which input becomes part of an SQL command. | [201-09](201-hero-to-super-hero/phase-3-data/09-stored-procedures-and-raw-sql.md) |
| Authentication | Proving who the caller is. | [201-10](201-hero-to-super-hero/phase-4-security-and-quality/10-jwt-authentication-and-authorization.md) |
| Authorization | Deciding what an authenticated caller may do. | [201-10](201-hero-to-super-hero/phase-4-security-and-quality/10-jwt-authentication-and-authorization.md) |
| JWT | JSON Web Token: a signed token whose payload holds claims; encoded, not encrypted. | [201-10](201-hero-to-super-hero/phase-4-security-and-quality/10-jwt-authentication-and-authorization.md) |
| Claim | A statement in a token or identity, such as `sub` (who) or `role`. | [201-10](201-hero-to-super-hero/phase-4-security-and-quality/10-jwt-authentication-and-authorization.md) |
| Bearer token | A token sent in the `Authorization: Bearer ...` header; whoever holds it is trusted. | [201-10](201-hero-to-super-hero/phase-4-security-and-quality/10-jwt-authentication-and-authorization.md) |
| Authorization policy | A named, reusable rule such as "requires the claim `notes:write`". | [201-10](201-hero-to-super-hero/phase-4-security-and-quality/10-jwt-authentication-and-authorization.md) |
| Unit test | A fast test of one class with its collaborators replaced. | [201-11](201-hero-to-super-hero/phase-4-security-and-quality/11-testing-and-notes-api.md) |
| Integration test | A test of several parts working together, such as the real HTTP pipeline. | [201-11](201-hero-to-super-hero/phase-4-security-and-quality/11-testing-and-notes-api.md) |
| Fact / Theory | xUnit test kinds: a fact is always true; a theory runs once per data row. | [201-11](201-hero-to-super-hero/phase-4-security-and-quality/11-testing-and-notes-api.md) |
| Fake | A small working replacement for a dependency, such as an in-memory repository. | [201-11](201-hero-to-super-hero/phase-4-security-and-quality/11-testing-and-notes-api.md) |
| Arrange, Act, Assert | The three parts of a test: set up, do one thing, check the result. | [201-11](201-hero-to-super-hero/phase-4-security-and-quality/11-testing-and-notes-api.md) |
| WebApplicationFactory | A test helper that starts the real app in memory and gives you an `HttpClient`. | [201-11](201-hero-to-super-hero/phase-4-security-and-quality/11-testing-and-notes-api.md) |
| Multi-stage build | A Dockerfile with several `FROM` stages so only the final, small stage is shipped. | [201-11](201-hero-to-super-hero/phase-4-security-and-quality/11-testing-and-notes-api.md) |
| Non-root container | A container whose process runs as an unprivileged user. | [201-11](201-hero-to-super-hero/phase-4-security-and-quality/11-testing-and-notes-api.md) |
| Composition root | The one place (usually `Program.cs`) that decides which implementation each interface gets. | [201-11](201-hero-to-super-hero/phase-4-security-and-quality/11-testing-and-notes-api.md) |

## C# 301 terms

| Term | Meaning | Lesson |
|---|---|---|
| Dependency rule | Source code dependencies point only inward, toward business rules. | [301-01](301-super-hero-to-legendary/phase-1-architecture/01-clean-architecture-and-vertical-slices.md) |
| Vertical slice | All the code of one feature (request, validation, handler, response) in one folder. | [301-01](301-super-hero-to-legendary/phase-1-architecture/01-clean-architecture-and-vertical-slices.md) |
| REPR | Request, Endpoint, Response: one endpoint class with its own request and response types. | [301-01](301-super-hero-to-legendary/phase-1-architecture/01-clean-architecture-and-vertical-slices.md) |
| Composition root | The one place where concrete classes are chosen and wired together. | [301-01](301-super-hero-to-legendary/phase-1-architecture/01-clean-architecture-and-vertical-slices.md) |
| ADR | Architecture decision record: context, decision, consequences and when to revisit. | [301-01](301-super-hero-to-legendary/phase-1-architecture/01-clean-architecture-and-vertical-slices.md) |
| CQRS | Command Query Responsibility Segregation: separate models or code paths for writes and reads. | [301-02](301-super-hero-to-legendary/phase-1-architecture/02-cqrs-without-ceremony.md) |
| Command | A message that asks to change state and answers only whether it worked. | [301-02](301-super-hero-to-legendary/phase-1-architecture/02-cqrs-without-ceremony.md) |
| Query | A message that returns data and never changes state. | [301-02](301-super-hero-to-legendary/phase-1-architecture/02-cqrs-without-ceremony.md) |
| Decorator | A class with the same interface as another that wraps it to add one concern. | [301-02](301-super-hero-to-legendary/phase-1-architecture/02-cqrs-without-ceremony.md) |
| Mediator | A component that dispatches a message to its handler at run time, hiding who handles it. | [301-02](301-super-hero-to-legendary/phase-1-architecture/02-cqrs-without-ceremony.md) |
| Ubiquitous language | The words the business and the code share, down to method names. | [301-03](301-super-hero-to-legendary/phase-1-architecture/03-domain-driven-design-essentials.md) |
| Entity | An object with an identity that persists while its values change. | [301-03](301-super-hero-to-legendary/phase-1-architecture/03-domain-driven-design-essentials.md) |
| Value object | An immutable object with no identity, equal when all its values are equal. | [301-03](301-super-hero-to-legendary/phase-1-architecture/03-domain-driven-design-essentials.md) |
| Aggregate | A cluster of objects changed together as one consistency unit. | [301-03](301-super-hero-to-legendary/phase-1-architecture/03-domain-driven-design-essentials.md) |
| Aggregate root | The one object of an aggregate that outsiders may call; it guards the invariants. | [301-03](301-super-hero-to-legendary/phase-1-architecture/03-domain-driven-design-essentials.md) |
| Invariant | A business rule that must be true every time the aggregate is saved. | [301-03](301-super-hero-to-legendary/phase-1-architecture/03-domain-driven-design-essentials.md) |
| Domain event | A past-tense fact raised by the domain, such as OrderSubmitted. | [301-03](301-super-hero-to-legendary/phase-1-architecture/03-domain-driven-design-essentials.md) |
| Bounded context | The boundary inside which one model and one language are consistent. | [301-03](301-super-hero-to-legendary/phase-1-architecture/03-domain-driven-design-essentials.md) |
| Primitive obsession | Using raw strings and numbers for concepts that deserve their own type. | [301-03](301-super-hero-to-legendary/phase-1-architecture/03-domain-driven-design-essentials.md) |
| Allocation | Taking memory from the managed heap for a new object, string or array. | [301-04](301-super-hero-to-legendary/phase-2-performance/04-performance-fundamentals.md) |
| Span | A ref struct view over existing memory that allocates nothing; it cannot live on the heap. | [301-04](301-super-hero-to-legendary/phase-2-performance/04-performance-fundamentals.md) |
| ValueTask | A task-like struct that avoids an allocation when the result is ready synchronously; await it once. | [301-04](301-super-hero-to-legendary/phase-2-performance/04-performance-fundamentals.md) |
| Baseline | The version of the code that every other measurement is compared with. | [301-04](301-super-hero-to-legendary/phase-2-performance/04-performance-fundamentals.md) |
| Dead-code elimination | The compiler removing code whose result is never used, which can make a benchmark meaningless. | [301-04](301-super-hero-to-legendary/phase-2-performance/04-performance-fundamentals.md) |
| Cache stampede | Many callers missing the same key at once and all hitting the source. | [301-05](301-super-hero-to-legendary/phase-2-performance/05-caching.md) |
| HybridCache | A two-level cache (in-process plus distributed) with stampede protection and tags. | [301-05](301-super-hero-to-legendary/phase-2-performance/05-caching.md) |
| Time to live (TTL) | How long a cache entry may be served before it expires. | [301-05](301-super-hero-to-legendary/phase-2-performance/05-caching.md) |
| Staleness budget | The agreed maximum age of data a reader may be shown. | [301-05](301-super-hero-to-legendary/phase-2-performance/05-caching.md) |
| Negative caching | Caching a "not found" answer briefly so missing keys do not hit the source every time. | [301-05](301-super-hero-to-legendary/phase-2-performance/05-caching.md) |
| Resilience pipeline | An ordered chain of strategies (timeout, retry, breaker, bulkhead) around one operation. | [301-06](301-super-hero-to-legendary/phase-3-resilience-and-messaging/06-resilience-with-polly.md) |
| Jitter | Random variation added to retry delays so clients do not retry in lock step. | [301-06](301-super-hero-to-legendary/phase-3-resilience-and-messaging/06-resilience-with-polly.md) |
| Circuit breaker | A guard that stops calling a failing dependency for a while and then probes it. | [301-06](301-super-hero-to-legendary/phase-3-resilience-and-messaging/06-resilience-with-polly.md) |
| Bulkhead | A limit on concurrent calls to one dependency so it cannot use all capacity. | [301-06](301-super-hero-to-legendary/phase-3-resilience-and-messaging/06-resilience-with-polly.md) |
| Retry storm | Retries from many callers multiplying the load on a dependency that is already failing. | [301-06](301-super-hero-to-legendary/phase-3-resilience-and-messaging/06-resilience-with-polly.md) |
| Idempotency key | A caller-supplied id that lets the server recognize and ignore a repeated request. | [301-06](301-super-hero-to-legendary/phase-3-resilience-and-messaging/06-resilience-with-polly.md) |
| Dual write | Changing two systems (a database and a broker) with no shared transaction, so a crash can leave them inconsistent. | [301-07](301-super-hero-to-legendary/phase-3-resilience-and-messaging/07-background-services-outbox-and-sagas.md) |
| Outbox pattern | Writing a message to a table in the same transaction as the change, and delivering it later. | [301-07](301-super-hero-to-legendary/phase-3-resilience-and-messaging/07-background-services-outbox-and-sagas.md) |
| At-least-once delivery | A guarantee that a message is never silently lost but may arrive more than once. | [301-07](301-super-hero-to-legendary/phase-3-resilience-and-messaging/07-background-services-outbox-and-sagas.md) |
| Inbox (idempotent consumer) | A table of handled message ids that makes repeated deliveries harmless. | [301-07](301-super-hero-to-legendary/phase-3-resilience-and-messaging/07-background-services-outbox-and-sagas.md) |
| Saga | A sequence of local transactions with compensating actions instead of a distributed transaction. | [301-07](301-super-hero-to-legendary/phase-3-resilience-and-messaging/07-background-services-outbox-and-sagas.md) |
| Compensation | A business action that semantically undoes an earlier step, such as a refund. | [301-07](301-super-hero-to-legendary/phase-3-resilience-and-messaging/07-background-services-outbox-and-sagas.md) |
| Dead letter | A parked message that failed too many times and needs a human or a replay. | [301-07](301-super-hero-to-legendary/phase-3-resilience-and-messaging/07-background-services-outbox-and-sagas.md) |
| Observability | Being able to answer new questions about a running system from its telemetry. | [301-08](301-super-hero-to-legendary/phase-3-resilience-and-messaging/08-observability-with-opentelemetry.md) |
| Span (trace) | One timed operation inside a trace; in .NET an Activity. | [301-08](301-super-hero-to-legendary/phase-3-resilience-and-messaging/08-observability-with-opentelemetry.md) |
| OTLP | The OpenTelemetry protocol for sending traces, metrics and logs. | [301-08](301-super-hero-to-legendary/phase-3-resilience-and-messaging/08-observability-with-opentelemetry.md) |
| Collector | A service that receives, processes and forwards telemetry between apps and backends. | [301-08](301-super-hero-to-legendary/phase-3-resilience-and-messaging/08-observability-with-opentelemetry.md) |
| Cardinality | The number of distinct values (and so time series) a metric label can produce. | [301-08](301-super-hero-to-legendary/phase-3-resilience-and-messaging/08-observability-with-opentelemetry.md) |
| Sampling | Keeping only a fraction of traces to control cost; head or tail based. | [301-08](301-super-hero-to-legendary/phase-3-resilience-and-messaging/08-observability-with-opentelemetry.md) |
| RED and USE | Rate, Errors, Duration for services; Utilization, Saturation, Errors for resources. | [301-08](301-super-hero-to-legendary/phase-3-resilience-and-messaging/08-observability-with-opentelemetry.md) |
| Modular monolith | One deployable with hard module boundaries and public contracts. | [301-09](301-super-hero-to-legendary/phase-4-production/09-modular-monolith-to-microservices.md) |
| Distributed monolith | Services that must be deployed and fail together, with all the costs of distribution. | [301-09](301-super-hero-to-legendary/phase-4-production/09-modular-monolith-to-microservices.md) |
| Client credentials grant | The OAuth 2.0 flow in which a service obtains a token for itself with its id and secret. | [301-09](301-super-hero-to-legendary/phase-4-production/09-modular-monolith-to-microservices.md) |
| Service account | The identity that a service uses when it calls another service. | [301-09](301-super-hero-to-legendary/phase-4-production/09-modular-monolith-to-microservices.md) |
| Audience (aud) | The claim naming the service a token is meant for. | [301-09](301-super-hero-to-legendary/phase-4-production/09-modular-monolith-to-microservices.md) |
| Confused deputy | A service using a token or permission meant for someone else. | [301-09](301-super-hero-to-legendary/phase-4-production/09-modular-monolith-to-microservices.md) |
| Least privilege | Granting each caller only the permissions it needs. | [301-09](301-super-hero-to-legendary/phase-4-production/09-modular-monolith-to-microservices.md) |
| Native AOT | Compiling to a self-contained native executable at publish time, with no JIT at run time. | [301-10](301-super-hero-to-legendary/phase-4-production/10-native-aot-analyzers-and-production-readiness.md) |
| Source generator | A compiler plug-in that writes code at build time, replacing run-time reflection. | [301-10](301-super-hero-to-legendary/phase-4-production/10-native-aot-analyzers-and-production-readiness.md) |
| Analyzer | A compiler component that reports problems in code as warnings or errors by rule id. | [301-10](301-super-hero-to-legendary/phase-4-production/10-native-aot-analyzers-and-production-readiness.md) |
| EditorConfig | A settings file that tells editors and analyzers the style and rule severities for a folder tree. | [301-10](301-super-hero-to-legendary/phase-4-production/10-native-aot-analyzers-and-production-readiness.md) |
| Directory.Build.props | An MSBuild file whose settings apply to every project below its folder. | [301-10](301-super-hero-to-legendary/phase-4-production/10-native-aot-analyzers-and-production-readiness.md) |
| Runtime identifier (RID) | The OS, CPU and C library a published app targets, for example linux-musl-x64. | [301-10](301-super-hero-to-legendary/phase-4-production/10-native-aot-analyzers-and-production-readiness.md) |
| Liveness and readiness | Liveness says the process is alive; readiness says it should receive traffic. | [301-10](301-super-hero-to-legendary/phase-4-production/10-native-aot-analyzers-and-production-readiness.md) |
| Production readiness review | Checking a service against a written checklist with evidence, and ranking the findings. | [301-10](301-super-hero-to-legendary/phase-4-production/10-native-aot-analyzers-and-production-readiness.md) |
