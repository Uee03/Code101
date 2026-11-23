cmake_minimum_required(VERSION 3.28)
project(smartptr LANGUAGES CXX)

# Put the finished program in build/out on every system.
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/$<1:out>")

add_executable(smartptr main.cpp)
target_compile_features(smartptr PRIVATE cxx_std_20)
set_target_properties(smartptr PROPERTIES CXX_EXTENSIONS OFF)

if(MSVC)
  target_compile_options(smartptr PRIVATE /W4 /permissive-)
else()
  target_compile_options(smartptr PRIVATE -Wall -Wextra -Wpedantic)
endif()
