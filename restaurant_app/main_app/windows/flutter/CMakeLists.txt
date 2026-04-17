# This file controls Flutter-level build steps. It should not be edited.
cmake_minimum_required(VERSION 3.14)

set(EPHEMERAL_DIR "${CMAKE_CURRENT_SOURCE_DIR}/ephemeral")

# Configuration provided via flutter tool.
include(${EPHEMERAL_DIR}/generated_config.cmake OPTIONAL)

# TODO: Move the rest of this into files in ephemeral. See
# https://github.com/flutter/flutter/issues/57146.

# Serves the same purpose as the list of plugins in the generated_plugin_registrant.h
# and generated_plugin_registrant.cc files, but for the Windows desktop embedding.
set(PLUGIN_LIST "")
if(DEFINED FLUTTER_TARGET_PLATFORM)
  if("${FLUTTER_TARGET_PLATFORM}" STREQUAL "windows-x64")
    set(PLUGIN_LIST "flutter_texture_registrar")
  endif()
endif()

# === Flutter Library ===
set(FLUTTER_LIBRARY "${EPHEMERAL_DIR}/flutter_windows.dll")

# Published to the flutter_windows.dll CMake interface library.
add_library(flutter INTERFACE)
target_include_directories(flutter INTERFACE
  "${EPHEMERAL_DIR}"
)
target_link_libraries(flutter INTERFACE "${FLUTTER_LIBRARY}.lib")
target_link_libraries(flutter INTERFACE "dwmapi.lib")

# To build the application, we need to copy the flutter_windows.dll
# and the icudtl.dat file to the output directory.
set(FLUTTER_ICU_DATA_FILE "${EPHEMERAL_DIR}/icudtl.dat")
set(FLUTTER_LIBRARY "${EPHEMERAL_DIR}/flutter_windows.dll")

# === Plugin registration ===
# Plugins that are built as shared libraries will have their import
# libraries linked here; the actual DLLs will be copied to the output
# directory by the plugin's own CMake rules.
set(PLUGIN_BUNDLED_LIBRARIES "")

foreach(plugin ${PLUGIN_LIST})
  target_link_libraries(flutter INTERFACE "${plugin}_interface")
endforeach()

# === Generated plugin registrant ===
add_library(generated_plugin_registrant STATIC
  "${CMAKE_CURRENT_SOURCE_DIR}/generated_plugin_registrant.cc"
)
target_include_directories(generated_plugin_registrant PUBLIC
  "${EPHEMERAL_DIR}"
)
target_link_libraries(generated_plugin_registrant PUBLIC flutter)
target_link_libraries(generated_plugin_registrant PUBLIC ${PLUGIN_LIST})
