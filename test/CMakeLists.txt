message(STATUS "Starting tests...")

set(TEST_DIRECTORIES TestCompileWarnings TestResolveRuntimeDependencies)

foreach(DIR IN LISTS TEST_DIRECTORIES)
    add_subdirectory(${DIR})
endforeach()
