#----------------------------------------------------------------
# Generated CMake target import file for configuration "Release".
#----------------------------------------------------------------

# Commands may need to know the format version.
set(CMAKE_IMPORT_FILE_VERSION 1)

# Import target "RtAudio::rtaudio" for configuration "Release"
set_property(TARGET RtAudio::rtaudio APPEND PROPERTY IMPORTED_CONFIGURATIONS RELEASE)
set_target_properties(RtAudio::rtaudio PROPERTIES
  IMPORTED_LOCATION_RELEASE "${_IMPORT_PREFIX}/lib/librtaudio.so.8.0.0"
  IMPORTED_SONAME_RELEASE "librtaudio.so.8"
  )

list(APPEND _cmake_import_check_targets RtAudio::rtaudio )
list(APPEND _cmake_import_check_files_for_RtAudio::rtaudio "${_IMPORT_PREFIX}/lib/librtaudio.so.8.0.0" )

# Commands beyond this point should not need to know the version.
set(CMAKE_IMPORT_FILE_VERSION)
