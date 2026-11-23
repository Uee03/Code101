cmake_minimum_required(VERSION 3.28)
project(tasks_desktop VERSION 0.1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/$<1:out>")

find_package(SDL3 CONFIG REQUIRED)
find_package(imgui CONFIG REQUIRED)
find_package(spdlog CONFIG REQUIRED)
find_package(cpr CONFIG REQUIRED)
find_package(nlohmann_json CONFIG REQUIRED)
find_package(tl-expected CONFIG REQUIRED)
find_package(OpenSSL REQUIRED)
find_package(httplib CONFIG REQUIRED)

add_library(tasks_warnings INTERFACE)
target_compile_options(tasks_warnings INTERFACE
    $<$<CXX_COMPILER_ID:MSVC>:/W4 /permissive- /utf-8>
    $<$<NOT:$<CXX_COMPILER_ID:MSVC>>:-Wall -Wextra -Wpedantic>)

# Everything that needs neither a window nor Dear ImGui: unit tests link this library.
add_library(tasks_core STATIC
    src/net/CprTransport.cpp
    src/api/ApiClient.cpp
    src/auth/Pkce.cpp
    src/auth/OidcClient.cpp
    src/auth/Session.cpp)
target_include_directories(tasks_core PUBLIC src)
target_link_libraries(tasks_core PUBLIC tasks_warnings cpr::cpr nlohmann_json::nlohmann_json tl::expected
    spdlog::spdlog OpenSSL::Crypto httplib::httplib)

add_executable(tasks_desktop
    src/main.cpp
    src/app/App.cpp
    src/app/Controller.cpp
    src/ui/Screens.cpp)
target_link_libraries(tasks_desktop PRIVATE tasks_core SDL3::SDL3 imgui::imgui)
