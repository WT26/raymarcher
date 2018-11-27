# CMake entry point
cmake_minimum_required (VERSION 3.0)
project (Raymarching)

find_package(OpenGL REQUIRED)

# Compile external dependencies 
add_subdirectory (external)

# On Visual 2005 and above, this module can set the debug working directory
cmake_policy(SET CMP0026 OLD)
list(APPEND CMAKE_MODULE_PATH "${CMAKE_SOURCE_DIR}/external/rpavlik-cmake-modules-fe2273")
include(CreateLaunchers)
include(MSVCMultipleProcessCompile) # /MP


include_directories(
	external/glfw-3.2.1/include/
	external/glm/
	external/glew-2.1.0/include/
	.
)

set(ALL_LIBS
	${OPENGL_LIBRARY}
	glfw
	GLEW
)

add_definitions(
	-DTW_STATIC
	-DTW_NO_LIB_PRAGMA
	-DTW_NO_DIRECT3D
	-DGLEW_STATIC
	-D_CRT_SECURE_NO_WARNINGS
)

add_executable(raymarching
	raymarching.cpp
	common/shader.cpp
	common/shader.hpp

	assignment.shader
	emptyVertex.shader
)
target_link_libraries(raymarching
	${ALL_LIBS}
)
# Visual working directory
create_target_launcher(raymarching WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}")

SOURCE_GROUP(common REGULAR_EXPRESSION ".*/common/.*" )
SOURCE_GROUP(shaders REGULAR_EXPRESSION ".*/.*shader$" )


