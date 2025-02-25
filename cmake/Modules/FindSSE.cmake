# Check if SSE instructions are available on the machine where 
# the project is compiled.

if(ARCH MATCHES "i386" OR ARCH MATCHES "x86_64")
  if(CMAKE_SYSTEM_NAME MATCHES "Linux")
    file(READ "/proc/cpuinfo" CPUINFO)

    string(REGEX REPLACE "^.*(sse2).*$" "\\1" SSE_THERE ${CPUINFO})
    string(COMPARE EQUAL "sse2" "${SSE_THERE}" SSE2_TRUE)
    if(SSE2_TRUE)
      set(SSE2_FOUND true CACHE BOOL "SSE2 available on host")
    else(SSE2_TRUE)
      set(SSE2_FOUND false CACHE BOOL "SSE2 available on host")
    endif(SSE2_TRUE)

    # /proc/cpuinfo apparently omits sse3 :(
    string(REGEX REPLACE "^.*[^s](sse3).*$" "\\1" SSE_THERE ${CPUINFO})
    string(COMPARE EQUAL "sse3" "${SSE_THERE}" SSE3_TRUE)
    if(NOT SSE3_TRUE)
      string(REGEX REPLACE "^.*(T2300).*$" "\\1" SSE_THERE ${CPUINFO})
      string(COMPARE EQUAL "T2300" "${SSE_THERE}" SSE3_TRUE)
    endif(NOT SSE3_TRUE)

    string(REGEX REPLACE "^.*(ssse3).*$" "\\1" SSE_THERE ${CPUINFO})
    string(COMPARE EQUAL "ssse3" "${SSE_THERE}" SSSE3_TRUE)
    if(SSE3_TRUE OR SSSE3_TRUE)
      set(SSE3_FOUND true CACHE BOOL "SSE3 available on host")
    else(SSE3_TRUE OR SSSE3_TRUE)
      set(SSE3_FOUND false CACHE BOOL "SSE3 available on host")
    endif(SSE3_TRUE OR SSSE3_TRUE)
    if(SSSE3_TRUE)
      set(SSSE3_FOUND true CACHE BOOL "SSSE3 available on host")
    else(SSSE3_TRUE)
      set(SSSE3_FOUND false CACHE BOOL "SSSE3 available on host")
    endif(SSSE3_TRUE)

    string(REGEX REPLACE "^.*(sse4_1).*$" "\\1" SSE_THERE ${CPUINFO})
    string(COMPARE EQUAL "sse4_1" "${SSE_THERE}" SSE41_TRUE)
    if(SSE41_TRUE)
      set(SSE4_1_FOUND true CACHE BOOL "SSE4.1 available on host")
    else(SSE41_TRUE)
      set(SSE4_1_FOUND false CACHE BOOL "SSE4.1 available on host")
    endif(SSE41_TRUE)

    string(REGEX REPLACE "^.*(sse4_2).*$" "\\1" SSE_THERE ${CPUINFO})
    string(COMPARE EQUAL "sse4_2" "${SSE_THERE}" SSE42_TRUE)
    if(SSE42_TRUE)
      set(SSE4_2_FOUND true CACHE BOOL "SSE4.2 available on host")
    else(SSE42_TRUE)
      set(SSE4_2_FOUND false CACHE BOOL "SSE4.2 available on host")
    endif(SSE42_TRUE)

  elseif(CMAKE_SYSTEM_NAME MATCHES "Darwin")
    exec_program("/usr/sbin/sysctl -n machdep.cpu.features" OUTPUT_VARIABLE CPUINFO)

    string(REGEX REPLACE "^.*[^S](SSE2).*$" "\\1" SSE_THERE ${CPUINFO})
    string(COMPARE EQUAL "SSE2" "${SSE_THERE}" SSE2_TRUE)
    if(SSE2_TRUE)
      set(SSE2_FOUND true CACHE BOOL "SSE2 available on host")
    else(SSE2_TRUE)
      set(SSE2_FOUND false CACHE BOOL "SSE2 available on host")
    endif(SSE2_TRUE)

    string(REGEX REPLACE "^.*[^S](SSE3).*$" "\\1" SSE_THERE ${CPUINFO})
    string(COMPARE EQUAL "SSE3" "${SSE_THERE}" SSE3_TRUE)
    if(SSE3_TRUE)
      set(SSE3_FOUND true CACHE BOOL "SSE3 available on host")
    else(SSE3_TRUE)
      set(SSE3_FOUND false CACHE BOOL "SSE3 available on host")
    endif(SSE3_TRUE)

    string(REGEX REPLACE "^.*(SSSE3).*$" "\\1" SSE_THERE ${CPUINFO})
    string(COMPARE EQUAL "SSSE3" "${SSE_THERE}" SSSE3_TRUE)
    if(SSSE3_TRUE)
      set(SSSE3_FOUND true CACHE BOOL "SSSE3 available on host")
    else(SSSE3_TRUE)
      set(SSSE3_FOUND false CACHE BOOL "SSSE3 available on host")
    endif(SSSE3_TRUE)

    string(REGEX REPLACE "^.*(SSE4.1).*$" "\\1" SSE_THERE ${CPUINFO})
    string(COMPARE EQUAL "SSE4.1" "${SSE_THERE}" SSE41_TRUE)
    if(SSE41_TRUE)
      set(SSE4_1_FOUND true CACHE BOOL "SSE4.1 available on host")
    else(SSE41_TRUE)
      set(SSE4_1_FOUND false CACHE BOOL "SSE4.1 available on host")
    endif(SSE41_TRUE)
    
    string(REGEX REPLACE "^.*(SSE4.2).*$" "\\1" SSE_THERE ${CPUINFO})
    string(COMPARE EQUAL "SSE4.2" "${SSE_THERE}" SSE42_TRUE)
    if(SSE42_TRUE)
      set(SSE4_2_FOUND true CACHE BOOL "SSE4.2 available on host")
    else(SSE42_TRUE)
      set(SSE4_2_FOUND false CACHE BOOL "SSE4.2 available on host")
    endif(SSE42_TRUE)
  elseif(CMAKE_SYSTEM_NAME MATCHES "Windows")
     # TODO
    set(SSE2_FOUND   true  CACHE BOOL "SSE2 available on host")
    set(SSE3_FOUND   false CACHE BOOL "SSE3 available on host")
    set(SSSE3_FOUND  false CACHE BOOL "SSSE3 available on host")
    set(SSE4_1_FOUND false CACHE BOOL "SSE4.1 available on host")
  else(CMAKE_SYSTEM_NAME MATCHES "Linux")
    set(SSE2_FOUND   true  CACHE BOOL "SSE2 available on host")
    set(SSE3_FOUND   false CACHE BOOL "SSE3 available on host")
    set(SSSE3_FOUND  false CACHE BOOL "SSSE3 available on host")
    set(SSE4_1_FOUND false CACHE BOOL "SSE4.1 available on host")
  endif(CMAKE_SYSTEM_NAME MATCHES "Linux")
endif(ARCH MATCHES "i386" OR ARCH MATCHES "x86_64")
if (CMAKE_SYSTEM_PROCESSOR MATCHES "^(aarch64.*|AARCH64.*|arm64.*|ARM64.*|armv8.*|ARMV8.*)")
  set(IS_ARM ON)
endif()

#message(STATUS "Hardware support for SSE2 on this machine: ${SSE2_FOUND}")
#message(STATUS "Hardware support for SSE3 on this machine: ${SSE3_FOUND}")
#message(STATUS "Hardware support for SSE4.1 on this machine: ${SSE4_1_FOUND}")
message(STATUS "Hardware support for SSE4.2 on this machine: ${SSE4_2_FOUND}")
