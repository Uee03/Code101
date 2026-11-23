cmake_minimum_required(VERSION 3.21)
project(expense_tracker C)

set(CMAKE_C_STANDARD 17)
set(CMAKE_C_STANDARD_REQUIRED ON)
set(CMAKE_C_EXTENSIONS OFF)

add_executable(app main.c expense.c)

if(MSVC)
  target_compile_options(app PRIVATE /W4)
  target_compile_definitions(app PRIVATE _CRT_SECURE_NO_WARNINGS)
else()
  target_compile_options(app PRIVATE -Wall -Wextra)
endif()
