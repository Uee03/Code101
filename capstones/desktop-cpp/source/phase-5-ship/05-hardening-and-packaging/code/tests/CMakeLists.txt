find_package(Catch2 3 CONFIG REQUIRED)
include(Catch)

# Every tests/test_*.cpp file is picked up; add a file and re-run cmake (CONFIGURE_DEPENDS also re-checks at build time).
file(GLOB TEST_SOURCES CONFIGURE_DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/test_*.cpp)

add_executable(tasks_tests ${TEST_SOURCES})
target_link_libraries(tasks_tests PRIVATE tasks_core Catch2::Catch2WithMain)
catch_discover_tests(tasks_tests)
