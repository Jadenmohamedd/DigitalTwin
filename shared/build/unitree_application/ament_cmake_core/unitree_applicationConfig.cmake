# generated from ament/cmake/core/templates/nameConfig.cmake.in

# prevent multiple inclusion
if(_unitree_application_CONFIG_INCLUDED)
  # ensure to keep the found flag the same
  if(NOT DEFINED unitree_application_FOUND)
    # explicitly set it to FALSE, otherwise CMake will set it to TRUE
    set(unitree_application_FOUND FALSE)
  elseif(NOT unitree_application_FOUND)
    # use separate condition to avoid uninitialized variable warning
    set(unitree_application_FOUND FALSE)
  endif()
  return()
endif()
set(_unitree_application_CONFIG_INCLUDED TRUE)

# output package information
if(NOT unitree_application_FIND_QUIETLY)
  message(STATUS "Found unitree_application: 0.1.0 (${unitree_application_DIR})")
endif()

# warn when using a deprecated package
if(NOT "" STREQUAL "")
  set(_msg "Package 'unitree_application' is deprecated")
  # append custom deprecation text if available
  if(NOT "" STREQUAL "TRUE")
    set(_msg "${_msg} ()")
  endif()
  # optionally quiet the deprecation message
  if(NOT unitree_application_DEPRECATED_QUIET)
    message(DEPRECATION "${_msg}")
  endif()
endif()

# flag package as ament-based to distinguish it after being find_package()-ed
set(unitree_application_FOUND_AMENT_PACKAGE TRUE)

# include all config extra files
set(_extras "")
foreach(_extra ${_extras})
  include("${unitree_application_DIR}/${_extra}")
endforeach()
