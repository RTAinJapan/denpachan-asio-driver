cmake_minimum_required(VERSION 3.25)

# denpachan-asio-driver: denpachan の ASIO 出力 (denpachan-asio-driver.dll)。GPL-3.0 (LICENSE)。
# 版はここだけに書く (README の「リリース」)。denpachan 本体とは ABI の版 (include/denpachan_asio.h) で合わせる
project(denpachan-asio-driver LANGUAGES CXX VERSION 0.1.0)

if(NOT WIN32)
    message(FATAL_ERROR "denpachan-asio-driver supports Windows only")
endif()

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

add_compile_definitions(
    UNICODE _UNICODE
    WIN32_LEAN_AND_MEAN NOMINMAX
    _WIN32_WINNT=0x0A00  # Windows 10+
)
if(MSVC)
    add_compile_options(/W4 /permissive- /utf-8 /Zc:__cplusplus /EHsc /MP)
    # Release でも PDB を出す (クラッシュダンプ解析用)
    add_compile_options("$<$<CONFIG:Release>:/Zi>")
    add_link_options("$<$<CONFIG:Release>:/DEBUG>" "$<$<CONFIG:Release>:/OPT:REF>" "$<$<CONFIG:Release>:/OPT:ICF>")
endif()

set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)

include(cmake/FetchAsioSdk.cmake)  # ヘッダだけ使う

add_library(denpachan-asio-driver SHARED
    src/asio_output.cpp
    include/denpachan_asio.h
)
target_compile_definitions(denpachan-asio-driver PRIVATE DENPACHAN_ASIO_EXPORTS)
target_include_directories(denpachan-asio-driver PRIVATE include)
target_include_directories(denpachan-asio-driver SYSTEM PRIVATE ${ASIOSDK_INCLUDE_DIRS})
target_link_libraries(denpachan-asio-driver PRIVATE ole32)

# 版の情報 (VERSIONINFO)。プレリリースのラベル (rc.1 など) は configure で DENPACHAN_VERSION_LABEL を渡したときだけ付ける
set(DENPACHAN_VERSION_LABEL "" CACHE STRING "Pre-release label added to the product version (e.g. rc.1)")
file(STRINGS include/denpachan_asio.h abi_line REGEX "#define DENPACHAN_ASIO_ABI_VERSION ")
string(REGEX REPLACE ".* ([0-9]+)$" "\\1" DENPACHAN_ASIO_ABI "${abi_line}")
if(DENPACHAN_VERSION_LABEL)
    set(DENPACHAN_PRODUCT_VERSION "${PROJECT_VERSION}-${DENPACHAN_VERSION_LABEL}")
    set(DENPACHAN_FILE_FLAGS "VS_FF_PRERELEASE")
else()
    set(DENPACHAN_PRODUCT_VERSION "${PROJECT_VERSION}")
    set(DENPACHAN_FILE_FLAGS "0")
endif()
configure_file(cmake/version.rc.in "${CMAKE_BINARY_DIR}/version.rc" @ONLY)
target_sources(denpachan-asio-driver PRIVATE "${CMAKE_BINARY_DIR}/version.rc")

# ライセンス文を出力フォルダの licenses/ に置く (配布の zip に入れる)
set(licenses "${CMAKE_BINARY_DIR}/bin/$<CONFIG>/licenses")
add_custom_target(denpachan_asio_licenses ALL
    COMMAND ${CMAKE_COMMAND} -E make_directory "${licenses}"
    COMMAND ${CMAKE_COMMAND} -E copy_if_different "${CMAKE_SOURCE_DIR}/LICENSE" "${licenses}/denpachan-asio-driver.txt"
    COMMAND ${CMAKE_COMMAND} -E copy_if_different "${ASIOSDK_LICENSE}" "${licenses}/asiosdk.txt"
    COMMENT "Copying licenses" VERBATIM)
