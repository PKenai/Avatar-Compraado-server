cmake_minimum_required(VERSION 3.20)

# ---------------------------------------------------------------------------
# The Forgotten Server (0.4 lineage, protocol 8.60) - Windows / MSVC x64 build
# Rebuilt against modern vcpkg dependencies (Boost 1.90, LuaJIT, libxml2, gmp,
# libmysql, OpenSSL, zlib). Configure with the vcpkg toolchain, e.g.:
#
#   cmake -S . -B build -A x64 ^
#     -DCMAKE_TOOLCHAIN_FILE=C:/vcpkg/scripts/buildsystems/vcpkg.cmake ^
#     -DVCPKG_TARGET_TRIPLET=x64-windows
#   cmake --build build --config Release
#
# The original Linux/autotools CMakeLists is preserved as CMakeLists.unix.txt.
# ---------------------------------------------------------------------------

project(theforgottenserver CXX)

if(NOT CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE Release)
endif()

set(CMAKE_CXX_STANDARD 14)          # 2013-era code: keep auto_ptr / register / throw specs
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# --- Sources (mirrors the Makefile.am / original CMake list) ---------------
set(SRC
    weapons.cpp waitlist.cpp vocation.cpp trashholder.cpp tools.cpp tile.cpp
    thing.cpp textlogger.cpp teleport.cpp talkaction.cpp spectators.cpp
    status.cpp spells.cpp spawn.cpp server.cpp scriptmanager.cpp scheduler.cpp
    raids.cpp quests.cpp protocolold.cpp protocollogin.cpp protocolhttp.cpp
    protocolgame.cpp protocol.cpp position.cpp player.cpp party.cpp
    spiritualrift.cpp
    outputmessage.cpp outfit.cpp otserv.cpp npc.cpp networkmessage.cpp
    movement.cpp mounts.cpp monsters.cpp monster.cpp map.cpp manager.cpp
    mailbox.cpp luascript.cpp items.cpp itemattributes.cpp item.cpp
    iomapserialize.cpp iomap.cpp iologindata.cpp ioguild.cpp ioban.cpp
    housetile.cpp house.cpp group.cpp globalevent.cpp gameservers.cpp game.cpp
    fileloader.cpp exception.cpp dispatcher.cpp depot.cpp reward.cpp momopouch.cpp databasemysql.cpp
    databasemanager.cpp database.cpp cylinder.cpp creatureevent.cpp
    creature.cpp container.cpp connection.cpp configmanager.cpp condition.cpp
    combat.cpp chat.cpp beds.cpp baseevents.cpp allocator.cpp admin.cpp
    actions.cpp auras.cpp wings.cpp shaders.cpp pets.cpp buff.cpp
)

add_executable(theforgottenserver ${SRC})

# --- Dependencies -----------------------------------------------------------
find_package(Boost REQUIRED COMPONENTS system thread regex filesystem)
find_package(LibXml2 REQUIRED)
find_package(OpenSSL REQUIRED)
find_package(ZLIB REQUIRED)

# vcpkg keeps release libs in <triplet>/lib and debug libs in <triplet>/debug/lib.
# The three deps below have no CMake config module, so we locate each config
# explicitly and select with a generator expression, otherwise find_library
# grabs the debug variant and mismatches the Release CRT.
set(_REL_LIB "${_VCPKG_INSTALLED_DIR}/${VCPKG_TARGET_TRIPLET}/lib")
set(_DBG_LIB "${_VCPKG_INSTALLED_DIR}/${VCPKG_TARGET_TRIPLET}/debug/lib")

# LuaJIT (5.1 ABI).
find_path(LUA_INCLUDE_DIR NAMES luajit.h lua.h PATH_SUFFIXES luajit luajit-2.1)
find_library(LUA_LIBRARY_RELEASE NAMES luajit-5.1 lua51 luajit lua5.1 lua PATHS "${_REL_LIB}" NO_DEFAULT_PATH)
find_library(LUA_LIBRARY_DEBUG   NAMES luajit-5.1 lua51 luajit lua5.1 lua PATHS "${_DBG_LIB}" NO_DEFAULT_PATH)

# GMP (rsa.cpp uses the mpz_* API).
find_path(GMP_INCLUDE_DIR NAMES gmp.h)
find_library(GMP_LIBRARY_RELEASE NAMES gmp mpir PATHS "${_REL_LIB}" NO_DEFAULT_PATH)
find_library(GMP_LIBRARY_DEBUG   NAMES gmp mpir PATHS "${_DBG_LIB}" NO_DEFAULT_PATH)

# MySQL client (libmariadb provides the MySQL C API).
find_path(MYSQL_INCLUDE_DIR NAMES mysql.h PATH_SUFFIXES mysql mariadb)
find_library(MYSQL_LIBRARY_RELEASE NAMES libmariadb mariadb libmysql mysqlclient PATHS "${_REL_LIB}" NO_DEFAULT_PATH)
find_library(MYSQL_LIBRARY_DEBUG   NAMES libmariadb mariadb libmysql mysqlclient PATHS "${_DBG_LIB}" NO_DEFAULT_PATH)

foreach(v LUA_INCLUDE_DIR LUA_LIBRARY_RELEASE GMP_INCLUDE_DIR GMP_LIBRARY_RELEASE MYSQL_INCLUDE_DIR MYSQL_LIBRARY_RELEASE)
    if(NOT ${v})
        message(FATAL_ERROR "Could not locate ${v}. Is the matching vcpkg package installed for this triplet?")
    endif()
    message(STATUS "${v} = ${${v}}")
endforeach()

# Fall back to release lib if a debug variant is absent.
foreach(dep LUA GMP MYSQL)
    if(NOT ${dep}_LIBRARY_DEBUG)
        set(${dep}_LIBRARY_DEBUG "${${dep}_LIBRARY_RELEASE}")
    endif()
    set(${dep}_LIBRARY "$<IF:$<CONFIG:Debug>,${${dep}_LIBRARY_DEBUG},${${dep}_LIBRARY_RELEASE}>")
endforeach()

target_include_directories(theforgottenserver PRIVATE
    ${LUA_INCLUDE_DIR} ${GMP_INCLUDE_DIR} ${MYSQL_INCLUDE_DIR}
    ${LIBXML2_INCLUDE_DIR}
)

target_link_libraries(theforgottenserver PRIVATE
    Boost::system Boost::thread Boost::regex Boost::filesystem
    LibXml2::LibXml2 OpenSSL::Crypto OpenSSL::SSL ZLIB::ZLIB
    ${LUA_LIBRARY} ${GMP_LIBRARY} ${MYSQL_LIBRARY}
)

# --- Feature / platform defines ---------------------------------------------
target_compile_definitions(theforgottenserver PRIVATE
    __USE_MYSQL__
    __NO_CRYPTOPP__
    __LUAJIT__                   # we link LuaJIT: pull in luajit.h + let us control the JIT engine
    __ENABLE_SERVER_DIAGNOSTIC__
    _CRT_SECURE_NO_WARNINGS
    _CRT_NONSTDC_NO_WARNINGS
    _WINSOCK_DEPRECATED_NO_WARNINGS
    _SCL_SECURE_NO_WARNINGS
    NOMINMAX
    WIN32_LEAN_AND_MEAN
    _WIN32_WINNT=0x0601          # Windows 7 - Boost.Asio needs >= Vista
    BOOST_ASIO_ENABLE_CANCELIO
    BOOST_BIND_GLOBAL_PLACEHOLDERS
)

if(MSVC)
    # 2013-era code is not conformance-clean; relax the front-end.
    # /Zi generates debug symbols so the crash handler can resolve function names.
    # vcpkg forces `/external:I` for its own include dir, which the PCH can't
    # resolve.  Override with a plain `/I` so `#include <libxml/xmlmemory.h>`
    # is found normally.
    target_compile_options(theforgottenserver PRIVATE
        "/I${LIBXML2_INCLUDE_DIR}"
        /permissive- /EHsc /bigobj /MP /Zi /utf-8
        /wd4996 /wd4267 /wd4244 /wd4018 /wd4309 /wd4250 /wd4244
    )
    # /DEBUG produces the .pdb (kept out-of-band, exe stays optimized).
    # /LARGEADDRESSAWARE allows the 32-bit binary to address up to 4 GB on 64-bit Windows.
    target_link_options(theforgottenserver PRIVATE /DEBUG /OPT:REF /OPT:ICF /LARGEADDRESSAWARE)
    # Winsock + system libs (dbghelp for the crash stack-trace handler).
    target_link_libraries(theforgottenserver PRIVATE ws2_32 mswsock dbghelp)
endif()
