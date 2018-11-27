// Include standard headers
#include <stdio.h>
#include <stdlib.h>
#include <vector>
#include <iostream>

// Include GLEW
#include <GL/glew.h>

// Include GLFW
#include <GLFW/glfw3.h>
GLFWwindow* window;

// Include GLM
#include <glm/glm.hpp>
#include <glm/gtc/matrix_transform.hpp>
#include <glm/gtc/type_ptr.hpp>	 // value_ptr(matrix)
using namespace glm;

#include <common/shader.hpp>	 // Loading shaders
#include <Windows.h>			 // Sleep


// ** Camera settings **
// Angles to be used in rotating the camera.
float u_vertical = 0.0f;
float u_horizontal = 0.0f;
float u_focalLength = 1.67f;
vec3 initialCameraPosition = vec3(0.0f, 0.0f, -2.0f);
vec3 initialCameraUp = normalize(vec3(0.0f, 1.0f, 0.0f));
vec3 initialCameraRight = normalize(vec3(1.0f, 0.0f, 0.0f));
vec3 u_cameraPosition = initialCameraPosition;
vec3 u_cameraUp = initialCameraUp;
vec3 u_cameraRight = initialCameraRight;

// Using up and right vectors, forward vector is created
vec3 u_cameraForward = cross(u_cameraRight, u_cameraUp);
float g_zNear = 0.0f;
float g_zFar = 15.0f;

float u_movementSpeed = 0.05f;
const float mouseXSensitivity = 0.005f;
const float mouseySensitivity = 0.005f;

vec3 u_skyColor = vec3(0.0, 0.4f, 0.4f);

const float TWO_PI = 6.28318530718f;

const int windowWidth = 640;
const int windowHeight = 480;
float g_aspectRatio = windowWidth / (float)windowHeight;

// Each frame calculate new camera position and rotation according to input.
void moveCamera(float deltaTime)
{
	// Camera position is changed if buttons "WASD" or arrows are pressed
	if ((glfwGetKey(window, GLFW_KEY_UP) == GLFW_PRESS) || ((glfwGetKey(window, GLFW_KEY_W) == GLFW_PRESS))) {
		u_cameraPosition += u_cameraForward * u_movementSpeed;
	}
	else if ((glfwGetKey(window, GLFW_KEY_DOWN) == GLFW_PRESS) || ((glfwGetKey(window, GLFW_KEY_S) == GLFW_PRESS))) {
		u_cameraPosition -= u_cameraForward * u_movementSpeed;
	}
	if ((glfwGetKey(window, GLFW_KEY_LEFT) == GLFW_PRESS) || ((glfwGetKey(window, GLFW_KEY_A) == GLFW_PRESS))) {
		u_cameraPosition -= u_cameraRight * u_movementSpeed;
	}
	else if ((glfwGetKey(window, GLFW_KEY_RIGHT) == GLFW_PRESS) || ((glfwGetKey(window, GLFW_KEY_D) == GLFW_PRESS))) {
		u_cameraPosition += u_cameraRight * u_movementSpeed;
	}

	// Camera moves along up vector when space or shift is pressed.
	if (glfwGetKey(window, GLFW_KEY_SPACE) == GLFW_PRESS) {
		u_cameraPosition += u_cameraUp * u_movementSpeed;
	}
	else if (glfwGetKey(window, GLFW_KEY_LEFT_SHIFT) == GLFW_PRESS) {
		u_cameraPosition -= u_cameraUp * u_movementSpeed;
	}

	// If key 'R' is pressed, camera is reset.
	if (glfwGetKey(window, GLFW_KEY_R) == GLFW_PRESS) {
		u_cameraPosition = initialCameraPosition;
		u_cameraUp = initialCameraUp;
		u_cameraRight = initialCameraRight;
		u_vertical = 0.0f;
		u_horizontal = 0.0f;
		glfwSetCursorPos(window, windowWidth / 2, windowHeight / 2);
	}

	// Calculate cursor's delta x & y
	double xpos, ypos;
	glfwGetCursorPos(window, &xpos, &ypos);
	glfwSetCursorPos(window, windowWidth / 2, windowHeight / 2);
	int dx = xpos - windowWidth / 2;
	int dy = ypos - windowHeight / 2;

	// Rotate angle according to sensitivity
	u_horizontal += dx * mouseXSensitivity;
	u_vertical += dy * mouseySensitivity;

	// Full circle, rotate back
	if (u_horizontal > TWO_PI) u_horizontal -= TWO_PI;
	else if (u_horizontal < 0.0f) u_horizontal += TWO_PI;
	if (u_vertical > TWO_PI) u_vertical -= TWO_PI;
	else if (u_vertical < 0.0f) u_vertical += TWO_PI;

	// Calculate new forward, right and up vectors
	float sintheta = sinf(u_horizontal);
	float costheta = cosf(u_horizontal);
	float sinphi = sinf(u_vertical);
	float cosphi = cosf(u_vertical);
	u_cameraForward = vec3(cosphi * sintheta, -sinphi, cosphi * costheta);
	u_cameraRight = vec3(costheta, 0.0f, -sintheta);
	u_cameraUp = normalize(cross(u_cameraForward, u_cameraRight));
}


int main(void)
{
	// Initialise GLFW. GLFW gives window and OpenGL context and handles e.g. inputs
	if (!glfwInit())
	{
		fprintf(stderr, "ERROR: Could not start GLFWn");
		getchar();
		return -1;
	}

	// GLFW Settings
	glfwWindowHint(GLFW_SAMPLES, 4);
	glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 3);
	glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 3);
	glfwWindowHint(GLFW_OPENGL_PROFILE, GLFW_OPENGL_CORE_PROFILE);

	// Open a window and create its OpenGL context
	window = glfwCreateWindow(windowWidth, windowHeight, "Raymarching", NULL, NULL);
	if (window == NULL) {
		fprintf(stderr, "ERROR: Could not create window.\n");
		getchar();
		glfwTerminate();
		return -1;
	}
	
	// Make window as current context
	glfwMakeContextCurrent(window);

	// Initialize GLEW. Glew gives OpenGL API and extensions in single header.
	glewExperimental = true;
	if (glewInit() != GLEW_OK) {
		fprintf(stderr, "Failed to initialize GLEW\n");
		getchar();
		glfwTerminate();
		return -1;
	}

	// Allow input
	glfwSetInputMode(window, GLFW_STICKY_KEYS, GL_TRUE);
	glfwPollEvents();

	// Move cursor to the center of the screen, and hide it.
	glfwSetCursorPos(window, windowWidth / 2, windowHeight / 2);
	glfwSetInputMode(window, GLFW_CURSOR, GLFW_CURSOR_DISABLED);

	// Load shaders
	GLuint programID = LoadShaders("emptyVertex.shader", "assignment.shader");
	glUseProgram(programID);

	// Only used vertices are the corners of the screen. 
	GLfloat vertices[] = {
		-1.0f, -1.0f,
		-1.0f,  1.0f,
		 1.0f, -1.0f,
		 1.0f,  1.0f
	};

	// Create vertex buffers and bind them.
	GLuint vao;
	glGenVertexArrays(1, &vao);
	glBindVertexArray(vao);

	GLuint vbo;
	glGenBuffers(1, &vbo);
	glBindBuffer(GL_ARRAY_BUFFER, vbo);
	glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_STATIC_DRAW);

	GLuint positionAttrib = glGetAttribLocation(programID, "position");
	glEnableVertexAttribArray(positionAttrib);
	glVertexAttribPointer(positionAttrib, 2, GL_FLOAT, GL_FALSE, 0, 0);

	// Find locations of uniforms.
	GLuint u_resolutionLocation = glGetUniformLocation(programID, "u_resolution");
	GLuint u_cameraUpLocation = glGetUniformLocation(programID, "u_cameraUp");
	GLuint u_cameraRightLocation = glGetUniformLocation(programID, "u_cameraRight");
	GLuint u_cameraForwardLocation = glGetUniformLocation(programID, "u_cameraForward");
	GLuint u_cameraPositionLocation = glGetUniformLocation(programID, "u_cameraPosition");
	GLuint u_focalLengthLocation = glGetUniformLocation(programID, "u_focalLength");
	GLuint u_aspectRatioLocation = glGetUniformLocation(programID, "u_aspectRatio");
	GLuint u_skyColorLocation = glGetUniformLocation(programID, "u_skyColor");
	GLuint u_timeLoc = glGetUniformLocation(programID, "u_time");

	// Send info about the created window to shaders
	glUniform2f(u_resolutionLocation, windowWidth, windowHeight);
	glUniform1f(u_aspectRatioLocation, g_aspectRatio);

	double lastTime = glfwGetTime();
	double printTime = lastTime;
	int nbFrames = 0;
	double targetFrameTime = 1.0 / 30.0;

	while (glfwGetKey(window, GLFW_KEY_ESCAPE) != GLFW_PRESS &&
		glfwWindowShouldClose(window) == 0)
	{
		// Measure speed
		double currentTime = glfwGetTime();
		float deltaTime = currentTime - lastTime;
		lastTime = currentTime;
		nbFrames++;
		if (currentTime - printTime >= 1.0) {
			printf("%f ms/frame\n", 1000.0 / double(nbFrames));
			nbFrames = 0;
			printTime += 1.0;
		}

		moveCamera(deltaTime);

		// Clear screen
		glClearColor(0, 0, 0, 0);
		glClear(GL_COLOR_BUFFER_BIT);

		// Update uniforms
		glUniform3fv(u_cameraUpLocation, 1, value_ptr(u_cameraUp));
		glUniform3fv(u_cameraRightLocation, 1, value_ptr(u_cameraRight));
		glUniform3fv(u_cameraForwardLocation, 1, value_ptr(u_cameraForward));
		glUniform3fv(u_cameraPositionLocation, 1, value_ptr(u_cameraPosition));
		glUniform1f(u_focalLengthLocation, u_focalLength);
		glUniform3fv(u_skyColorLocation, 1, value_ptr(u_skyColor));
		glUniform1f(u_timeLoc, currentTime);

		glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);

		glfwSwapBuffers(window);

		// Slow down to match target framerate
		if (deltaTime < targetFrameTime)
			Sleep(targetFrameTime - deltaTime);

		glfwPollEvents();
	}

	glDeleteProgram(programID);

	// Close OpenGL window and terminate GLFW
	glfwTerminate();

	return 0;

}
