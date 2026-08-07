cmake_minimum_required(VERSION 3.20)
project(skybridge_parser LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

add_executable(skybridge-parser src/main.cpp)
target_compile_options(skybridge-parser PRIVATE -Wall -Wextra -Wpedantic)