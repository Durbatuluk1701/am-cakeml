set(CMAKE_BUILD_TYPE_INIT Debug)
set(CMAKE_C_FLAGS_INIT_PREFIX -Wall)
if(DEFINED ENV{CMAKE_C_ARGS})
    set(CMAKE_C_FLAGS_INIT "${CMAKE_C_FLAGS_INIT_PREFIX} $ENV{CMAKE_C_ARGS}")
endif()

set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)
