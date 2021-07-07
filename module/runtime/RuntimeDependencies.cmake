function(resolve_runtime_dependencies TARGET)

    list(SUBLIST ARGV 1 ${ARGC} GET_RUNTIME_DEPENDENCIES_ARGS)

    list(PREPEND GET_RUNTIME_DEPENDENCIES_ARGS EXECUTABLES $<TARGET_FILE:${TARGET}>)
    list(PREPEND
         GET_RUNTIME_DEPENDENCIES_ARGS
         RESOLVED_DEPENDENCIES_VAR
         ${TARGET}_RESOLVED_DEPENDENCIES
    )
    list(PREPEND
         GET_RUNTIME_DEPENDENCIES_ARGS
         UNRESOLVED_DEPENDENCIES_VAR
         ${TARGET}_UNRESOLVED_DEPENDENCIES
    )
    list(PREPEND
         GET_RUNTIME_DEPENDENCIES_ARGS
         CONFLICTING_DEPENDENCIES_PREFIX
         ${TARGET}_CONFLICTING_DEPENDENCIES
    )

    set(TARGET_FILE_DIR $<TARGET_FILE_DIR:${TARGET}>)
    set(RUNTIME_DEPENDENCIES_SEARCH_PATHS ${CMAKE_FIND_ROOT_PATH})

    set(CONFIGURE_INPUT ${PROJECT_SOURCE_DIR}/cmake/GetRuntimeDependenciesScript.cmake)
    set(CONFIGURE_OUTPUT
        ${CMAKE_CURRENT_BINARY_DIR}/${TARGET}ResolveRuntimeDependencies.cmake.CONFIGURED
    )

    configure_file(${CONFIGURE_INPUT} ${CONFIGURE_OUTPUT} @ONLY)

    set(GENERATE_INPUT ${CONFIGURE_OUTPUT})
    set(GENERATE_OUTPUT
        ${CMAKE_CURRENT_BINARY_DIR}/${TARGET}ResolveRuntimeDependencies$<CONFIG>.cmake
    )

    file(GENERATE OUTPUT ${GENERATE_OUTPUT} INPUT ${GENERATE_INPUT})

    # add_custom_command(OUTPUT ${TARGET}_RUNTIME_DEPENDENCIES.cmake COMMAND ${CMAKE_COMMAND}
    # -DTARGET=${TARGET} -DTARGET_FILE=$<TARGET_FILE:${TARGET}> -P
    # ${CMAKE_CURRENT_SOURCE_DIR}/TEST.cmake COMMAND ${CMAKE_COMMAND} -E echo "Creating
    # ${TARGET}_RUNTIME_DEPENDENCIES.cmake" WORKING_DIRECTORY $<TARGET_FILE_DIR:${TARGET}> )

    # add_custom_command(TARGET ${TARGET} POST_BUILD COMMAND ${CMAKE_COMMAND} -DTARGET=${TARGET}
    # -DTARGET_FILE=$<TARGET_FILE:${TARGET}> -P ${CMAKE_CURRENT_SOURCE_DIR}/TEST.cmake COMMAND
    # ${CMAKE_COMMAND} -E echo "Creating ${TARGET}_RUNTIME_DEPENDENCIES.cmake" WORKING_DIRECTORY
    # $<TARGET_FILE_DIR:${TARGET}> )

    # add_custom_target(resolve_dependencies ALL DEPENDS ${TARGET}_RUNTIME_DEPENDENCIES.cmake )
    # add_custom_command(TARGET ${TARGET} COMMAND ${CMAKE_COMMAND} -P ${GENERATE_OUTPUT} )

endfunction()

# Print a fatal error if one of the variables is not defined.
function(REQUIRE_DEFINED)
    foreach(VAR_NAME IN LISTS ARGV)
        if(NOT DEFINED ${VAR_NAME})
            message(FATAL_ERROR "Require ${VAR_NAME} to be defined")
        endif()
    endforeach()
endfunction()

function(get_target_property_recursive OUTPUT_VAR TARGET PROPERTY)
    get_target_property(RESULTS ${TARGET} ${PROPERTY})

    if(NOT RESULTS)
        return()
    else()
        set(RECURSE_RES)
        foreach(RES_TARGET IN LISTS RESULTS)

            set(OUTPUT_RES)
            get_target_property_recursive(OUTPUT_RES ${RES_TARGET} ${PROPERTY})

            list(APPEND RECURSE_RES ${OUTPUT_RES})

        endforeach()

        set(${OUTPUT_VAR} ${RESULTS} ${RECURSE_RES} PARENT_SCOPE)
    endif()
endfunction()

set(GRD_ARGUMENTS
    RESOLVED_DEPENDENCIES_VAR
    UNRESOLVED_DEPENDENCIES_VAR
    CONFLICTING_DEPENDENCIES_PREFIX
    EXECUTABLES
    LIBRARIES
    MODULES
    DIRECTORIES
    BUNDINCLUDE_REGEXES
    PRE_LE_EXECUTABLE
    PRE_EXCLUDE_REGEXES
    POST_INCLUDE_REGEXES
    POST_EXCLUDE_REGEXES
)

function(target_resolve_runtime_dependencies)

    set(RRD_MULTI_VALUE_ARGUMENTS
        DIRECTORIES
        PRE_INCLUDE_REGEXES
        PRE_EXCLUDE_REGEXES
        POST_INCLUDE_REGEXES
        POST_EXCLUDE_REGEXES
    )

    cmake_parse_arguments(PARSE_ARGV
                          1
                          "RRD" # Parsed keywords prefix
                          "" # Optional keywords
                          "" # Single-value keywords
                          "${RRD_MULTI_VALUE_ARGUMENTS}" # Multi-value keywords
    )

    set(TARGET ${ARGV0})
    get_target_property(TARGET_TYPE ${TARGET} TYPE)

    # Set EXECUTABLES, LIBRARIES or MODULES argument depending on target type.
    if(NOT TARGET_TYPE)
        message(FATAL_ERROR "${ARGV0} is not a target!")
    elseif(TARGET_TYPE STREQUAL "EXECUTABLE")
        get_target_property(IS_MACOSX_BUNDLE ${TARGET} MACOSX_BUNDLE)
        if(IS_MACOSX_BUNDLE)
            set(BUNDLE_EXECUTABLE $<TARGET_FILE:${TARGET}>)
        else()
            set(EXECUTABLES $<TARGET_FILE:${TARGET}>)
        endif()
    elseif(TARGET_TYPE STREQUAL "SHARED_LIBRARY")
        set(LIBRARIES $<TARGET_FILE:${TARGET}>)
    elseif(TARGET_TYPE STREQUAL "MODULE_LIBRARY")
        set(MODULES $<TARGET_FILE:${TARGET}>)
    else()
        message(FATAL_ERROR "${TARGET} type ${TARGET_TYPE} is not supported!")
    endif()

    # Get recursively all linked libraries of ${TARGET}
    get_target_property_recursive(TARGET_LINK_LIBRARIES ${TARGET} LINK_LIBRARIES)
    message(STATUS "TARGET_LINK_LIBRARIES: ${TARGET_LINK_LIBRARIES}")

    list(PREPEND RRD_DIRECTORIES ${CMAKE_FIND_ROOT_PATH}) # cross compilation root path

    # If shared library add directory
    foreach(LIBRARY IN LISTS TARGET_LINK_LIBRARIES)
        get_target_property(LIBRARY_TYPE ${LIBRARY} TYPE)
        if(NOT LIBRARY_TYPE MATCHES "^(INTERFACE|OBJECT)_LIBRARY$")
            list(APPEND RRD_DIRECTORIES $<TARGET_FILE_DIR:${LIBRARY}>)
        endif()
    endforeach()

    message(STATUS "TARGET_LINK_LIBRARIES_DIR: ${RRD_DIRECTORIES}")

    # Forward defined RRD function arguments GRD function arguments.
    foreach(ARG IN LISTS RRD_MULTI_VALUE_ARGUMENTS)
        if(DEFINED RRD_${ARG})
            set(${ARG} ${RRD_${ARG}})
        endif()
    endforeach()

    set(OUTPUT ${TARGET}_RUNTIME_DEPENDENCIES.cmake)
    set(RESOLVED_DEPENDENCIES_VAR ${TARGET}_RESOLVED_DEPENDENCIES)
    set(UNRESOLVED_DEPENDENCIES_VAR ${TARGET}_UNRESOLVED_DEPENDENCIES)
    set(CONFLICTING_DEPENDENCIES_PREFIX ${TARGET}_CONFLICTING_DEPENDENCIES)

    # Forward defined GRD function arguments to custom command's script arguments.
    set(SCRIPT_ARGUMENTS)
    foreach(ARG IN ITEMS ${GRD_ARGUMENTS} OUTPUT)
        if(DEFINED ${ARG})
            string(REPLACE ";" "\\\;" ESCAPED_ARG_VALUE "${${ARG}}")
            list(APPEND SCRIPT_ARGUMENTS -D${ARG}=${ESCAPED_ARG_VALUE})
        endif()
    endforeach()
    message(STATUS "SCRIPT_ARGUMENTS: ${SCRIPT_ARGUMENTS}")

    # Escape string content string(REPLACE ":" "_" TARGET ${TARGET})

    # add_custom_target(${TARGET}_resolve_runtime_dependencies
    add_custom_command(TARGET ${TARGET}
                       POST_BUILD
                       # add_custom_command(OUTPUT ${OUTPUT}
                       COMMAND
                           ${CMAKE_COMMAND} ${SCRIPT_ARGUMENTS} -P
                           ${CMAKE_CURRENT_SOURCE_DIR}/WriteRuntimeDependencies.cmake
                       # DEPENDS ${TARGET} MAIN_DEPENDENCY ${TARGET} COMMAND ${CMAKE_COMMAND} -E
                       # echo "Creating ${TARGET}_RUNTIME_DEPENDENCIES.cmake" BYPRODUCTS ${OUTPUT}
                       # WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR} #$<TARGET_FILE_DIR:${TARGET}>
                       WORKING_DIRECTORY $<TARGET_FILE_DIR:${TARGET}>
                       COMMENT "Resolve ${TARGET} runtime dependencies..."
                       VERBATIM
    )

endfunction()

function(add_deploy_runtime_dependencies_target)

    set(TARGET ${ARGV0})

    # list(SUBLIST ARGV 1 ${ARGC} FILE_ARGS)

    # add_library(deploy_runtime_dependencies INTERFACE ${TARGET}_RUNTIME_DEPENDENCIES.cmake)
    # add_custom_target(${TARGET}_deploy_runtime_dependencies ALL
    add_custom_command(TARGET ${TARGET}
                       POST_BUILD
                       # DEPENDS ${TARGET}
                       DEPENDS
                       ${TARGET}_RUNTIME_DEPENDENCIES.cmake
                       # DEPENDS ${TARGET}_resolve_runtime_dependencies
                       COMMAND
                           ${CMAKE_COMMAND} -DTARGET=${TARGET} -P
                           ${CMAKE_CURRENT_SOURCE_DIR}/DeployRuntimeDependencies.cmake
                       WORKING_DIRECTORY $<TARGET_FILE_DIR:${TARGET}>
                       COMMENT "Deploy ${TARGET} runtime dependencies..."
                       VERBATIM
    )

    # include()

    # file(COPY)

endfunction()
