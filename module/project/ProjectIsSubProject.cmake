# This function must be called before the first project(....) call of the current project.
function(project_is_subproject IS_SUBPROJECT)

    if(DEFINED PROJECT_NAME)
        set(${IS_SUBPROJECT} TRUE PARENT_SCOPE)
    else()
        set(${IS_SUBPROJECT} FALSE PARENT_SCOPE)
    endif()

endfunction()
