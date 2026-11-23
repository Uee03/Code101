cmake_minimum_required(VERSION 3.28)
project(tasks_desktop VERSION 0.1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/$<1:out>")

find_package(SDL3 CONFIG REQUIRED)
find_package(imgui CONFIG REQUIRED)
find_package(spdlog CONFIG REQUIRED)

add_library(tasks_warnings INTERFACE)
target_compile_options(tasks_warnings INTERFACE
    $<$<CXX_COMPILER_ID:MSVC>:/W4 /permissive- /utf-8>
    $<$<NOT:$<CXX_COMPILER_ID:MSVC>>:-Wall -Wextra -Wpedantic>)

add_executable(tasks_desktop src/main.cpp src/app/App.cpp)
target_include_directories(tasks_desktop PRIVATE src)
target_link_libraries(tasks_desktop PRIVATE tasks_warnings SDL3::SDL3 imgui::imgui spdlog::spdlog)
