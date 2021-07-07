cmake_minimum_required(VERSION 3.16 FATAL_ERROR)

# ---------- [project:definitions]

project(CMakeModulesExtra VERSION 1.0.0)

# ---------- [project:modules]

include(GNUInstallDirs)

# ---------- [project:tests]

if(BUILD_TESTING OR ${PROJECT_NAME}_BUILD_TESTING)
    enable_testing()
    add_subdirectory(test)
endif()
