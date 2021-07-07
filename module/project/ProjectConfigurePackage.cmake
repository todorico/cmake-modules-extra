include(CMakePackageConfigHelpers)

set(${PROJECT_NAME}_CMAKE_CONFIG_DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/${PROJECT_NAME})

configure_package_config_file(${PROJECT_SOURCE_DIR}/cmake/ProjectPackageConfig.cmake.in
                              ${PROJECT_BINARY_DIR}/${PROJECT_NAME}Config.cmake
                              INSTALL_DESTINATION ${${PROJECT_NAME}_CMAKE_CONFIG_DESTINATION}
)

write_basic_package_version_file("${PROJECT_BINARY_DIR}/${PROJECT_NAME}ConfigVersion.cmake"
                                 VERSION ${PROJECT_VERSION}
                                 COMPATIBILITY SameMajorVersion
)

install(FILES
            ${PROJECT_BINARY_DIR}/${PROJECT_NAME}Config.cmake
            ${PROJECT_BINARY_DIR}/${PROJECT_NAME}ConfigVersion.cmake
        DESTINATION ${${PROJECT_NAME}_CMAKE_CONFIG_DESTINATION}
)

include(CPack)
