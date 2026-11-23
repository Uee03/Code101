---
track: c
level: 101
phase: 2
phase_name: building-blocks
lesson: 08
title: "Structs"
time: 45 min
prerequisites: [101.2.06, 101.2.07]
versions: { c_standard: "C17", gcc: "any recent version (11 or newer)" }
verified: not yet run
source: source/c/101-zero-to-hero/phase-2-building-blocks/08-structs/
assets: []
---

# 08. Structs

> **Draft: written but not yet run.** The code and the expected output in this lesson were prepared by reading the code and the official documentation. They have not been executed yet. If something does not behave as described, trust your tool's real output and report it.

## What you will be able to do
By the end of this lesson you will be able to:
- define a `struct` type with `typedef` and create variables of it;
- read and change fields with `.` and `->`;
- pass a struct to a function by pointer;
- explain that assigning one struct to another makes a copy.

## Recap
1. What does `*p` mean? <details><summary>Answer</summary>The value stored at the address held in `p`.</details>
2. Why do arrays need a size or a terminator? <details><summary>Answer</summary>C does not remember how long an array is; the program must know the count or the end marker (`'\0'` for strings).</details>

## Why it matters
A library card holds a name, a number and an expiry date together; you would never keep them on three unrelated slips. A **struct** bundles related values (its **fields**) into one record you can pass around as a unit.

## What you will build
A small shelf: an `Item` record with a name, a quantity and a price, a function to print it, a function to restock it, an array of three items with a total value, and a copy of a record.

## Before you start
- Finish lessons 06 and 07 (arrays and pointers).
- Time: 45 minutes.
- Source pack (optional): every file is shown in full in this lesson, so you can follow without it. The finished code, the exercise starter and the solution are in the
  course repository https://github.com/Uee03/Code101 under `source/c/101-zero-to-hero/phase-2-building-blocks/08-structs/` (on that page choose **Code, Download ZIP**, or run
  `git clone https://github.com/Uee03/Code101.git`).
- [How every lesson works](../../README.md#how-every-lesson-works) and [build and run](../../README.md#build-and-run) have the commands.
- Working folder: `lesson08`. Recovery: PowerShell `Set-Location "$HOME/code101/c/lesson08"`; macOS/Linux `cd "$HOME/code101/c/lesson08"`.

## Steps

### Step 1. Create the working folder
Repeat the [working-folder steps](../../README.md#working-folder) with the folder name `lesson08`. Open only `lesson08` in your editor and open a terminal there.

### Step 2. Ideas before the code
- `typedef struct { ... } Item;` defines a new type called `Item` with fields inside the braces. `typedef` means "give this type a name".
- `Item pen = {"Pen", 10, 1.50};` creates a variable and fills the fields in order.
- With a variable, you reach a field with a dot: `pen.quantity`. With a **pointer to** a struct you use an arrow: `item->quantity`, which is shorthand for `(*item).quantity`.
- Passing `const Item *item` avoids copying the record and `const` promises not to change it; passing `Item *item` lets the function change the original (as in lesson 07).
- `snprintf(buffer, size, "%s", text)` is `printf` that writes into an array, never more than `size` characters. We use it to put text in a name field safely. An array field cannot be assigned with `=`.

### Step 3. Write the program
Create `main.c` and paste the complete file:

**File: `main.c`**
```c
#include <stdio.h>

typedef struct {
    char name[20];
    int quantity;
    double price;
} Item;

void print_item(const Item *item);
void restock(Item *item, int amount);

int main(void) {
    Item pen = {"Pen", 10, 1.50};
    print_item(&pen);
    restock(&pen, 5);
    print_item(&pen);

    Item shelf[3] = {
        {"Notebook", 4, 3.25},
        {"Ruler", 6, 0.80},
        {"Eraser", 12, 0.50}
    };
    double value = 0.0;
    for (int i = 0; i < 3; i++) {
        print_item(&shelf[i]);
        value += shelf[i].quantity * shelf[i].price;
    }
    printf("Shelf value: %.2f\n", value);

    Item copy = pen;
    snprintf(copy.name, sizeof copy.name, "%s", "Spare");
    copy.quantity = 0;
    print_item(&copy);
    print_item(&pen);
    return 0;
}

void print_item(const Item *item) {
    printf("%s: %d at %.2f each = %.2f\n", item->name, item->quantity, item->price,
           item->quantity * item->price);
}

void restock(Item *item, int amount) {
    item->quantity += amount;
}
```

Save it. **Predict first:** after `Item copy = pen;` and changes to `copy`, will `pen` still show 15?

## Run it
Build (`gcc -std=c17 -Wall -Wextra -o app main.c`; Microsoft `cl`: see the README table) and run `./app` (macOS/Linux) or `.\app` (Windows).

Expected output (not yet run):

```text
Pen: 10 at 1.50 each = 15.00
Pen: 15 at 1.50 each = 22.50
Notebook: 4 at 3.25 each = 13.00
Ruler: 6 at 0.80 each = 4.80
Eraser: 12 at 0.50 each = 6.00
Shelf value: 23.80
Spare: 0 at 1.50 each = 0.00
Pen: 15 at 1.50 each = 22.50
```

## How it works
1. `Item pen = {"Pen", 10, 1.50};` fills `name`, `quantity` and `price` in the order they were declared.
2. `print_item(&pen)` passes the address; inside, `item->name` is the field of the original record. `restock(&pen, 5)` changes the original, so the second print shows 15.
3. `shelf[i].quantity` combines an array index and a field: `shelf[i]` is one `Item`, `.quantity` is its field. The braces in the initialiser mirror that: three inner `{...}` for three items.
4. `Item copy = pen;` copies **all** fields, including the whole `name` array, into a new record. Changing `copy` does not touch `pen`: that is why the last line still shows 15. Misconception: a struct is not shared when assigned; only a pointer is shared.
5. The sum `4*3.25 + 6*0.80 + 12*0.50` is 23.80.

## Try it
**Guided.** A `Book` record in `try08` (see [exercise folders](../../README.md#exercise-folders)). Complete `discount` so that it lowers the book's price by a percent. The compiler may warn about unused parameters until you use them.

**File: `main.c` (starter)**
```c
#include <stdio.h>

typedef struct {
    char title[30];
    int pages;
    double price;
} Book;

void print_book(const Book *book);
void discount(Book *book, double percent);

int main(void) {
    Book book = {"C Basics", 200, 40.00};
    print_book(&book);
    discount(&book, 25);
    print_book(&book);
    return 0;
}

void print_book(const Book *book) {
    printf("%s, %d pages, %.2f\n", book->title, book->pages, book->price);
}

void discount(Book *book, double percent) {
    /* TODO: lower the price of the book by the given percent. */
}
```

Expected output after you finish:

```text
C Basics, 200 pages, 40.00
C Basics, 200 pages, 30.00
```

**Change.** Add a function `is_long` that returns 1 when a book has more than 300 pages. **Stretch (optional):** make an array of three books and print the most expensive one.

<details><summary>Solution</summary>

Replace the body of `discount`; everything else is unchanged.

**File: `main.c` (solution)**
```c
#include <stdio.h>

typedef struct {
    char title[30];
    int pages;
    double price;
} Book;

void print_book(const Book *book);
void discount(Book *book, double percent);

int main(void) {
    Book book = {"C Basics", 200, 40.00};
    print_book(&book);
    discount(&book, 25);
    print_book(&book);
    return 0;
}

void print_book(const Book *book) {
    printf("%s, %d pages, %.2f\n", book->title, book->pages, book->price);
}

void discount(Book *book, double percent) {
    book->price = book->price * (100 - percent) / 100;
}
```

</details>

## Check yourself
1. When do you write `.` and when `->`?
   <details><summary>Answer</summary>`.` with a struct variable; `->` with a pointer to a struct.</details>
2. After `Item copy = pen; copy.quantity = 0;` what is `pen.quantity`?
   <details><summary>Answer</summary>Unchanged: the assignment made a separate copy.</details>
3. Why does `restock` take `Item *` while `print_item` takes `const Item *`?
   <details><summary>Answer</summary>`restock` changes the record; `print_item` only reads it.</details>
4. Why can you not write `copy.name = "Spare";`?
   <details><summary>Answer</summary>An array cannot be assigned with `=`; copy the characters with `snprintf` (or similar).</details>

## Common mistakes
| Symptom or error text | Cause | Fix |
|---|---|---|
| `error: invalid type argument of '->'` (typical message) | Used `->` on a struct variable, not a pointer | Use `.` for variables, or pass the address. |
| `error: request for member 'quantity' in something not a structure or union` (typical message) | Used `.` on a pointer | Use `->`. |
| `error: assignment to expression with array type` (typical message) | Tried `item.name = "..."` | Use `snprintf` into the array. |
| The record does not change after a function call | The function got a copy (`Item item`) instead of a pointer | Take `Item *item` and pass `&record`. |
| A long name is cut off | The name is longer than the array minus one | Make the array bigger or accept the cut: `snprintf` never overflows. |

## Best practice
Prefer `snprintf` to `strcpy` or `sprintf` when writing text into a fixed array, because it respects the size. Source: cppreference, snprintf https://en.cppreference.com/w/c/io/fprintf

## Going further
- Struct declarations: https://en.cppreference.com/w/c/language/struct

## Summary
- You defined a struct type and used its fields with `.` and `->`.
- You passed a struct by pointer to read or to change it.
- You made an array of structs and a copy of one.

## Next lesson
**[09. Headers and multiple files](09-headers-and-multiple-files.md):** split a program into several files and build them together.
