cmake_minimum_required(VERSION 3.20)
project(BoosterSyndrome VERSION 1.0.0 LANGUAGES C CXX)

set(CMAKE_C_STANDARD 11)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Compiler options
if(MSVC)
    add_compile_options(/W4)
else()
    add_compile_options(-Wall -Wextra -pedantic)
endif()

# Include directories
include_directories(${CMAKE_SOURCE_DIR}/services/c)
include_directories(${CMAKE_SOURCE_DIR}/services/cpp)

# C libraries
add_library(memory_allocator services/c/memory_allocator.c)
add_library(cryptography services/c/cryptography.c)

# C++ libraries
add_library(algorithms services/cpp/algorithms.cpp)
add_library(networking services/cpp/networking.cpp)

# Executables
add_executable(c_tests tests/c/memory_allocator_test.c)
target_link_libraries(c_tests memory_allocator)

add_executable(cpp_tests tests/cpp/algorithms_test.cpp)
target_link_libraries(cpp_tests algorithms)

# Enable testing
enable_testing()
add_test(NAME CTests COMMAND c_tests)
add_test(NAME CppTests COMMAND cpp_tests)
