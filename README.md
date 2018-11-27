# raymarcher
Simple C++ OpenGL Raymarcher

### Build & Compile & run (with CMake, Microsoft Visual C++ and Visual studio 2017):
Pull the code
Open CMake-GUI (https://cmake.org/download/)
Find source code where you downloaded them (browse source..)
Select Build location
Click Configure
Select generator Visual Studio 15 2017 -> OK
Click Generate until no errors occur
Go to Build folder and open .sln file in Visual Studio
Make "raymarching" project as active project and hit run

### Using the application
Move camera with WASD or arrow keys
Rotate camera with mouse
Move camera up and down with space and shift
Click R to reset the view

### Code
Raymarcher.cpp has the OpenGL starter
assingment.shader has the fragment shader with raymarching

### Libraries used in the application
GLEW - OpenGL API wrangler + extensions under one header
GLWF - Creating the window and handling input
GLM - Math functionalities

Used licences are written in licenses.txt
