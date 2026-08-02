cmake_minimum_required(VERSION 3.18.1)
project(anti_tamper)

add_library(anti_tamper SHARED anti_tamper.cpp)

# Ship it stripped — the point of native detection is to be annoying to read.
target_link_options(anti_tamper PRIVATE "-Wl,--strip-all")
