get_property(USING_MULTI_CONFIG_GENERATOR GLOBAL PROPERTY GENERATOR_IS_MULTI_CONFIG)

# Set default available configurations for multi config generators.
if(USING_MULTI_CONFIG_GENERATOR)

    set(CMAKE_CONFIGURATION_TYPES
        "RelWithDebInfo;Debug;Release;MinSizeRel"
        CACHE STRING "Available configurations." FORCE
    )

    message(STATUS
                "Using multiple configuration types: '${CMAKE_CONFIGURATION_TYPES}' as none was specified."
    )

endif()

# Set a default build type if none was specified.
if(NOT DEFINED CMAKE_BUILD_TYPE AND NOT DEFINED CMAKE_CONFIGURATION_TYPES)

    set(CMAKE_BUILD_TYPE RelWithDebInfo CACHE STRING "Choose the type of build." FORCE)
    # Set the possible values of build type for cmake-gui and ccmake.
    set_property(CACHE CMAKE_BUILD_TYPE
                 PROPERTY STRINGS "RelWithDebInfo" "Debug" "Release" "MinSizeRel"
    )

    message(STATUS "Using build type: '${CMAKE_BUILD_TYPE}' as none was specified.")

endif()
