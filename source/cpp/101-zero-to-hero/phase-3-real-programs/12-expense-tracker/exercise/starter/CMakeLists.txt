cmake_minimum_required(VERSION 3.28)
project(tracker LANGUAGES CXX)

# Put the finished program in build/out on every system.
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/$<1:out>")

add_executable(tracker main.cpp expense_book.cpp)
target_compile_features(tracker PRIVATE cxx_std_20)
set_target_properties(tracker PROPERTIES CXX_EXTENSIONS OFF)

if(MSVC)
  target_compile_options(tracker PRIVATE /W4 /permissive-)
else()
  target_compile_options(tracker PRIVATE -Wall -Wextra -Wpedantic)
endif()
