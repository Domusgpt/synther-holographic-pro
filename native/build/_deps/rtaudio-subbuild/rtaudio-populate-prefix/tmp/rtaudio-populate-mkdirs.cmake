# Distributed under the OSI-approved BSD 3-Clause License.  See accompanying
# file Copyright.txt or https://cmake.org/licensing for details.

cmake_minimum_required(VERSION 3.5)

file(MAKE_DIRECTORY
  "/mnt/c/Users/millz/Desktop/Synther_Refactored/native/build/_deps/rtaudio-src"
  "/mnt/c/Users/millz/Desktop/Synther_Refactored/native/build/_deps/rtaudio-build"
  "/mnt/c/Users/millz/Desktop/Synther_Refactored/native/build/_deps/rtaudio-subbuild/rtaudio-populate-prefix"
  "/mnt/c/Users/millz/Desktop/Synther_Refactored/native/build/_deps/rtaudio-subbuild/rtaudio-populate-prefix/tmp"
  "/mnt/c/Users/millz/Desktop/Synther_Refactored/native/build/_deps/rtaudio-subbuild/rtaudio-populate-prefix/src/rtaudio-populate-stamp"
  "/mnt/c/Users/millz/Desktop/Synther_Refactored/native/build/_deps/rtaudio-subbuild/rtaudio-populate-prefix/src"
  "/mnt/c/Users/millz/Desktop/Synther_Refactored/native/build/_deps/rtaudio-subbuild/rtaudio-populate-prefix/src/rtaudio-populate-stamp"
)

set(configSubDirs )
foreach(subDir IN LISTS configSubDirs)
    file(MAKE_DIRECTORY "/mnt/c/Users/millz/Desktop/Synther_Refactored/native/build/_deps/rtaudio-subbuild/rtaudio-populate-prefix/src/rtaudio-populate-stamp/${subDir}")
endforeach()
if(cfgdir)
  file(MAKE_DIRECTORY "/mnt/c/Users/millz/Desktop/Synther_Refactored/native/build/_deps/rtaudio-subbuild/rtaudio-populate-prefix/src/rtaudio-populate-stamp${cfgdir}") # cfgdir has leading slash
endif()
