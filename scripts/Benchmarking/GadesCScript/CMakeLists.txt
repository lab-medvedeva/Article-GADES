cmake_minimum_required(VERSION 3.5)

project(GadesCScript LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(ArrayFire REQUIRED)

add_executable(GadesCScript main.cpp)

target_link_libraries(GadesCScript armadillo ArrayFire::af)

include(GNUInstallDirs)
install(TARGETS GadesCScript
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)
