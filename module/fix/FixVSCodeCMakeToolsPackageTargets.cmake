# ---------- Description ----------
#
# Targets 'package' and 'package_source' are automaticaly defined by cpack. However, those targets
# are not accessible on the vscode-cmake-tools UI. We fix this problem by adding selectable custom
# targets 'make_package' and 'make_package_source' which will indirectly generate 'package' and
# 'package_source' targets.
#
# ---------- Requirement ----------
#
# 'include(CPack)' must be called to make those custom targets work properly.

add_custom_target(make_package
                  COMMAND
                      ${CMAKE_COMMAND} --build ${PROJECT_BINARY_DIR} --config $<CONFIG> --target
                      package
)

add_custom_target(make_package_source
                  COMMAND
                      ${CMAKE_COMMAND} --build ${PROJECT_BINARY_DIR} --config $<CONFIG> --target
                      package_source
)
