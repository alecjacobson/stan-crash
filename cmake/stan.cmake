include(FetchContent)

message(STATUS "Fetching Stan...")

FetchContent_Declare(
  stan
  URL https://github.com/stan-dev/math/archive/refs/tags/v4.9.0.tar.gz
  URL_MD5 468af66d69ba47dc8a59fb9206fd7159
  DOWNLOAD_EXTRACT_TIMESTAMP TRUE
)

# Make sure the content is downloaded and available
FetchContent_MakeAvailable(stan)

# Manually set up the include directories for Stan
set(STAN_INCLUDE_DIRS ${stan_SOURCE_DIR})

# stan comes with its own Eigen, Boost, sundials and tbb
file(GLOB BOOST_INCLUDE_DIR "${stan_SOURCE_DIR}/lib/boost_*")
file(GLOB EIGEN_INCLUDE_DIR "${stan_SOURCE_DIR}/lib/eigen_*")
file(GLOB SUNDIALS_INCLUDE_DIR "${stan_SOURCE_DIR}/lib/sundials_*/include")
file(GLOB TBB_INCLUDE_DIR "${stan_SOURCE_DIR}/lib/tbb_*/include")
file(GLOB TBB_SOURCE_DIR "${stan_SOURCE_DIR}/lib/tbb_*")


# Create an interface library for Stan
add_library(stan::stan INTERFACE IMPORTED GLOBAL)
target_include_directories(stan::stan INTERFACE 
  ${STAN_INCLUDE_DIRS}
  ${BOOST_INCLUDE_DIR}
  ${EIGEN_INCLUDE_DIR}
  ${SUNDIALS_INCLUDE_DIR}
)

# Add TBB using TBBBuild.cmake if available
if(EXISTS "${TBB_SOURCE_DIR}/cmake/TBBBuild.cmake")
    include(${TBB_SOURCE_DIR}/cmake/TBBBuild.cmake)
    tbb_build(TBB_ROOT ${TBB_SOURCE_DIR} CONFIG_DIR TBB_DIR)
    find_package(TBB REQUIRED CONFIG)
    message(STATUS "TBB found and built successfully.")
else()
    message(FATAL_ERROR "TBBBuild.cmake not found in TBB source directory.")
endif()

target_link_libraries(stan::stan INTERFACE TBB::tbb)
target_compile_definitions(stan::stan INTERFACE NO_FPRINTF_OUTPUT BOOST_DISABLE_ASSERTS TBB_INTERFACE_NEW _REENTRANT)
# add a compilation flag so that "[]/stan/math/prim/fun/Eigen.hpp" is included
# first
# https://github.com/stan-dev/math/issues/2879#issuecomment-1456241790
target_compile_options(stan::stan INTERFACE "-include" "stan/math/prim/fun/Eigen.hpp")

