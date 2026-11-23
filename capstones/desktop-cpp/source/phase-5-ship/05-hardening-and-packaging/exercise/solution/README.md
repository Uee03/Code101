# Overlay, not a second project

These files are copied over the same paths in your working copy of `../../code`. Everything else stays as it is.
Starter: `src/core/Validation.hpp` with a weak `isValidDueDate`, and `tests/test_validation.cpp` that fails until you fix it.
Solution: the strict `isValidDueDate`; the test file is the same (the tests are the specification).
Run `cmake --preset <os>` again after copying so that CMake finds the new test file.
