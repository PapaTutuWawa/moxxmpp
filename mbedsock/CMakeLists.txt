cmake_minimum_required(VERSION 3.7 FATAL_ERROR)
project(mbedsock VERSION 1.0.0 LANGUAGES C)
add_library(mbedsock SHARED mbedsock.c mbedsock.h mbedsock.def)

target_include_directories(mbedsock PUBLIC ${MBEDTLS_ROOT_DIR}/include)
target_link_libraries(mbedsock mbedtls mbedx509 mbedcrypto pthread)
link_directories(${MBEDTLS_ROOT_DIR}/lib)

set_target_properties(mbedsock PROPERTIES
    PUBLIC_HEADER mbedsock.h
    VERSION ${PROJECT_VERSION}
    SOVERSION 1
    OUTPUT_NAME "mbedsock"
    XCODE_ATTRIBUTE_CODE_SIGN_IDENTITY "Hex_Identity_ID_Goes_Here"
)
install(TARGETS mbedsock)
