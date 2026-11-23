cmake_minimum_required(VERSION 3.21)
project(tasksteams_desktop VERSION 0.1.0 LANGUAGES C)

set(CMAKE_C_STANDARD 17)
set(CMAKE_C_STANDARD_REQUIRED ON)
set(CMAKE_C_EXTENSIONS OFF)

option(TS_SANITIZE "Build with AddressSanitizer (and UBSan outside MSVC); use the asan preset" OFF)

# Nuklear is one header plus an SDL3 renderer header in the same git repository.
# SOURCE_SUBDIR points at a folder that does not exist, so CMake downloads the
# repository but does not run Nuklear's own CMakeLists.txt.
include(FetchContent)
FetchContent_Declare(
  nuklear
  GIT_REPOSITORY https://github.com/Immediate-Mode-UI/Nuklear.git
  GIT_TAG        v4.13.4
  GIT_SHALLOW    TRUE
  SOURCE_SUBDIR  no-cmake-here
)
FetchContent_MakeAvailable(nuklear)

find_package(SDL3 CONFIG REQUIRED)
find_package(CURL CONFIG REQUIRED)
find_package(cJSON CONFIG REQUIRED)
find_package(OpenSSL REQUIRED)
# vcpkg's cJSON exports the target "cjson"; upstream's own config names it "cJSON::cJSON".
if(TARGET cjson)
  set(TS_CJSON_TARGET cjson)
elseif(TARGET cJSON::cJSON)
  set(TS_CJSON_TARGET cJSON::cJSON)
else()
  message(FATAL_ERROR "cJSON was found but exports neither cjson nor cJSON::cJSON")
endif()

add_executable(tasksteams
  src/main.c
  src/util.c
  src/config.c
  src/log.c
  src/http.c
  src/model.c
  src/api.c
  src/pkce.c
  src/loopback.c
  src/auth.c
  src/jobs.c
  src/store.c
  src/ui.c
  src/ui_work.c
  src/nk_impl.c
)

target_include_directories(tasksteams PRIVATE src)
target_include_directories(tasksteams SYSTEM PRIVATE
  ${nuklear_SOURCE_DIR}
  ${nuklear_SOURCE_DIR}/demo/sdl3_renderer
)
target_link_libraries(tasksteams PRIVATE SDL3::SDL3 CURL::libcurl OpenSSL::Crypto ${TS_CJSON_TARGET})
if(UNIX)
  target_link_libraries(tasksteams PRIVATE m)
  # loopback.c uses POSIX sockets, which -std=c17 hides unless this is defined for that file only
  set_source_files_properties(src/loopback.c PROPERTIES COMPILE_DEFINITIONS _POSIX_C_SOURCE=200809L)
endif()
if(WIN32)
  target_link_libraries(tasksteams PRIVATE ws2_32)
endif()

# ---- warnings (all builds) and hardening (all builds that are not sanitizer builds) ----
include(CheckPIESupported)
check_pie_supported(LANGUAGES C)
set_property(TARGET tasksteams PROPERTY POSITION_INDEPENDENT_CODE TRUE) # position independent executable

if(MSVC)
  target_compile_options(tasksteams PRIVATE /W4 /utf-8 /external:W0 /GS /sdl /guard:cf)
  target_compile_definitions(tasksteams PRIVATE _CRT_SECURE_NO_WARNINGS)
  target_link_options(tasksteams PRIVATE /guard:cf /DYNAMICBASE /NXCOMPAT /HIGHENTROPYVA)
  set_source_files_properties(src/nk_impl.c PROPERTIES COMPILE_OPTIONS /w)
else()
  target_compile_options(tasksteams PRIVATE -Wall -Wextra -Wpedantic -Wformat=2 -Wformat-security
                                            -fstack-protector-strong)
  # _FORTIFY_SOURCE needs optimisation, so it is only switched on for Release
  target_compile_definitions(tasksteams PRIVATE $<$<CONFIG:Release>:_FORTIFY_SOURCE=2>)
  if(CMAKE_SYSTEM_NAME STREQUAL "Linux")
    target_link_options(tasksteams PRIVATE -Wl,-z,relro,-z,now) # full RELRO
  endif()
  set_source_files_properties(src/nk_impl.c PROPERTIES COMPILE_OPTIONS -w)
endif()

# ---- sanitizers (the asan preset) ----
if(TS_SANITIZE)
  if(MSVC)
    # MSVC's AddressSanitizer does not work with the runtime checks or incremental linking
    string(REGEX REPLACE "/RTC[1csu]+" "" CMAKE_C_FLAGS_DEBUG "${CMAKE_C_FLAGS_DEBUG}")
    target_compile_options(tasksteams PRIVATE /fsanitize=address)
    target_link_options(tasksteams PRIVATE /INCREMENTAL:NO)
  else()
    target_compile_options(tasksteams PRIVATE -fsanitize=address,undefined -fno-omit-frame-pointer -g)
    target_link_options(tasksteams PRIVATE -fsanitize=address,undefined)
  endif()
endif()

# ---- installing and packaging: cmake --install, then cpack ----
install(TARGETS tasksteams RUNTIME DESTINATION .)
install(FILES keycloak/tasks-desktop-client.json DESTINATION keycloak)
install(FILES packaging/THIRD-PARTY-NOTICES.md DESTINATION .)
if(WIN32)
  # the DLLs of SDL3, curl, cJSON and OpenSSL that the program needs
  install(FILES $<TARGET_RUNTIME_DLLS:tasksteams> DESTINATION .)
endif()

set(CPACK_GENERATOR ZIP)
set(CPACK_PACKAGE_NAME tasksteams)
set(CPACK_PACKAGE_VERSION ${PROJECT_VERSION})
set(CPACK_INCLUDE_TOPLEVEL_DIRECTORY ON)
include(CPack)
