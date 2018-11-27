#version 150

// Tampere University of Technology
// TIE-52306 Computer Graphics Coding Assignment 2018
//
// Write your name and student id here:
//   example name, 123456
//
// Mark here with an X what functionalities you implemented
// Note that different functionalities are worth different amount of points.
//
// Name of the functionality      |Done| Notes
//-------------------------------------------------------------------------------
// example functionality          | X  | Example note: control this with var YYYY
// Madatory functionalities -----------------------------------------------------
//   Perspective projection       | x  |
//   Phong shading                | x  |
//   Camera movement and rotation | x  |
// Extra funtionalities ---------------------------------------------------------
//   Attend visiting lecture 1    | x  |
//   Attend visiting lecture 2    |    |
//   Tone mapping                 |    |
//   PBR shading                  |    |
//   Sharp shadows                |    |
//   Soft shadows                 | x  |
//   Sharp reflections            |    |
//   Glossy refelctions           |    |
//   Refractions                  |    |
//   Caustics                     |    |
//   Texturing                    |    |
//   Simple game                  |    |
//   Progressive path tracing     |    |
//   Basic post-processing        |    |
//   Advanced post-processing     |    |
//   Simple own SDF               |    |
//   Advanced own SDF             |    |
//   Animated SDF                 |    |
//   Other?                       |    |
//   AntiAliasing                 | x  |
//   C++ / OpenGL Launcher		  | x  |
//   AmbientOcclusion             | x  |

#ifdef GL_ES
precision mediump float;
#endif

#define PI 3.14159265359
#define EPSILON 0.00001

// These definitions are tweakable.

/* Minimum distance a ray must travel. Raising this value yields some performance
 * benefits for secondary rays at the cost of weird artefacts around object
 * edges.
 */
#define MIN_DIST 0.08
 /* Maximum distance a ray can travel. Changing it has little to no performance
  * benefit for indoor scenes, but useful when there is nothing for the ray
  * to intersect with (such as the sky in outdoors scenes).
  */
#define MAX_DIST 20.0
  /* Maximum number of steps the ray can march. High values make the image more
   * correct around object edges at the cost of performance, lower values cause
   * weird black hole-ish bending artefacts but is faster.
   */
#define MARCH_MAX_STEPS 128
   /* Typically, this doesn't have to be changed. Lower values cause worse
	* performance, but make the tracing stabler around slightly incorrect distance
	* functions.
	* The current value merely helps with rounding errors.
	*/
#define STEP_RATIO 0.999
	/* Determines what distance is considered close enough to count as an
	 * intersection. Lower values are more correct but require more steps to reach
	 * the surface
	 */
#define HIT_RATIO 0.001

smooth in vec2 uv;
out vec4 outColor;

// Time since startup, in seconds
uniform float u_time;

// Camera
uniform vec2 u_resolution;
uniform vec3 u_cameraUp;
uniform vec3 u_cameraRight;
uniform vec3 u_cameraForward;
uniform vec3 u_cameraPosition;
uniform float u_focalLength;
uniform float u_aspectRatio;

uniform vec3 u_skyColor;

struct material
{
	// The color of the surface
	vec4 color;
	// You can add your own material features here!
};

// Good resource for finding more building blocks for distance functions:
// http://www.iquilezles.org/www/articles/distfunctions/distfunctions.htm

/* Basic box distance field.
 *
 * Parameters:
 *  p   Point for which to evaluate the distance field
 *  b   "Radius" of the box
 *
 * Returns:
 *  Distance to the box from point p.
 */
float box(vec3 p, vec3 b)
{
	vec3 d = abs(p) - b;
	return min(max(d.x, max(d.y, d.z)), 0.0) + length(max(d, 0.0));
}

/* Rotates point around origin along the X axis.
 *
 * Parameters:
 *  p   The point to rotate
 *  a   The angle in radians
 *
 * Returns:
 *  The rotated point.
 */
vec3 rot_x(vec3 p, float a)
{
	float s = sin(a);
	float c = cos(a);
	return vec3(
		p.x,
		c*p.y - s * p.z,
		s*p.y + c * p.z
	);
}

/* Rotates point around origin along the Y axis.
 *
 * Parameters:
 *  p   The point to rotate
 *  a   The angle in radians
 *
 * Returns:
 *  The rotated point.
 */
vec3 rot_y(vec3 p, float a)
{
	float s = sin(a);
	float c = cos(a);
	return vec3(
		c*p.x + s * p.z,
		p.y,
		-s * p.x + c * p.z
	);
}

/* Rotates point around origin along the Z axis.
 *
 * Parameters:
 *  p   The point to rotate
 *  a   The angle in radians
 *
 * Returns:
 *  The rotated point.
 */
vec3 rot_z(vec3 p, float a)
{
	float s = sin(a);
	float c = cos(a);
	return vec3(
		c*p.x - s * p.y,
		s*p.x + c * p.y,
		p.z
	);
}

/* Each object has a distance function and a material function. The distance
 * function evaluates the distance field of the object at a given point, and
 * the material function determines the surface material at a point.
 */

float blob_distance(vec3 p)
{
	vec3 q = p - vec3(-0.5, -2.2 + abs(sin(u_time*3.0)), 2.0);
	return length(q) - 0.8 + sin(10.0*q.x)*sin(10.0*q.y)*sin(10.0*q.z)* 0.128 * sin(u_time * 6.0);
}

material blob_material(vec3 p)
{
	material mat;
	mat.color = vec4(1.0, 0.5, 0.3, 0.0);
	return mat;
}

float sphere_distance(vec3 p)
{
	return length(p - vec3(1.5, -1.8, 4.0)) - 1.2;
}

material sphere_material(vec3 p)
{
	material mat;
	mat.color = vec4(u_cameraRight, 1.0);
	return mat;
}

float room_distance(vec3 p)
{
	return max(
		-box(p - vec3(0.0, 3.0, 3.0), vec3(0.5, 0.5, 0.5)),
		-box(p - vec3(0.0, 0.0, 0.0), vec3(3.0, 3.0, 6.0))
	);
}

material room_material(vec3 p)
{
	material mat;
	mat.color = vec4(1.0, 1.0, 1.0, 1.0);
	if (p.x <= -2.98) mat.color.rgb = vec3(1.0, 0.0, 0.0);
	else if (p.x >= 2.98) mat.color.rgb = vec3(0.0, 1.0, 0.0);
	return mat;
}

float crate_distance(vec3 p)
{
	return box(rot_y(p - vec3(-1, -1, 5), u_time), vec3(1, 2, 1));
}

material crate_material(vec3 p)
{
	material mat;
	mat.color = vec4(1.0, 1.0, 1.0, 1.0);

	vec3 q = rot_y(p - vec3(-1, -1, 5), u_time) * 0.98;
	if (fract(q.x + floor(q.y*2.0) * 0.5 + floor(q.z*2.0) * 0.5) < 0.5)
	{
		mat.color.rgb = vec3(0.0, 1.0, 1.0);
	}
	return mat;
}

// Boombox
float complex_distance(vec3 p)
{
	float t = u_time * 0.7;
	t = (mod(t, 2.) < 1. ? 1. : -1.) * (fract(t) * 2. - 1.);

	// body
	float b1 = box(rot_y(p - vec3(1, 0.2, 1), t), vec3(1, 0.5, 0.2));
	
	// Handle
	float scalez = 0.3;
	float b2 = box(rot_y(p - vec3(1, 0.8, 1), t), vec3(0.6, 0.1, 0.3 * scalez));
	float b3 = box(rot_y(p - vec3(1, 0.8, 1), t), vec3(0.7, 0.2, 0.2 * scalez));
	float gap = max(-b2, b3);


	return min(b1, gap);
}

material complex_material(vec3 p)
{
	material mat;
	mat.color = vec4(1.0, 1.0, 1.0, 1.0);

	return mat;
}


/* The distance function collecting all others.
 *
 * Parameters:
 *  p   The point for which to find the nearest surface
 *  mat The material of the nearest surface
 *
 * Returns:
 *  The distance to the nearest surface.
 */
float map(
	in vec3 p,
	out material mat
) {
	float min_dist = MAX_DIST * 2.0;
	float dist = 0.0;

	dist = blob_distance(p);
	if (dist < min_dist) {
		mat = blob_material(p);
		min_dist = dist;
	}

	dist = room_distance(p);
	if (dist < min_dist) {
		mat = room_material(p);
		min_dist = dist;
	}

	dist = crate_distance(p);
	if (dist < min_dist) {
		mat = crate_material(p);
		min_dist = dist;
	}

	dist = sphere_distance(p);
	if (dist < min_dist) {
		mat = sphere_material(p);
		min_dist = dist;
	}

	dist = complex_distance(p);
	if (dist < min_dist) {
		mat = complex_material(p);
		min_dist = dist;
	}


	// Add your own objects here!

	return min_dist;
}

float degreesToRadians(float degrees) {
	return degrees * PI / 180.0;
}

/* Calculates the normal of the surface closest to point p.
 *
 * Parameters:
 *  p   The point where the normal should be calculated
 *  mat The material information, produced as a byproduct
 *
 * Returns:
 *  The normal of the surface.
 *
 * See http://www.iquilezles.org/www/articles/normalsSDF/normalsSDF.htm if
 * you're interested in how this works.
 */
vec3 normal(vec3 p, out material mat)
{
	const vec2 k = vec2(1.0, -1.0);
	return normalize(
		k.xyy * map(p + k.xyy * EPSILON, mat) +
		k.yyx * map(p + k.yyx * EPSILON, mat) +
		k.yxy * map(p + k.yxy * EPSILON, mat) +
		k.xxx * map(p + k.xxx * EPSILON, mat)
	);
}

/* Finds the closest intersection of the ray with the scene.
 *
 * Parameters:
 *  o           Origin of the ray
 *  v           Direction of the ray
 *  max_dist    Maximum distance the ray can travel. Usually MAX_DIST.
 *  p           Location of the intersection
 *  n           Normal of the surface at the intersection point
 *  mat         Material of the intersected surface
 *  inside      Whether we are marching inside an object or not. Useful for
 *              refractions.
 *
 * Returns:
 *  true if a surface was hit, false otherwise.
 */
bool intersect(
	in vec3 o,
	in vec3 v,
	in float max_dist,
	out vec3 p,
	out vec3 n,
	out material mat,
	bool inside
) {
	float t = MIN_DIST;
	float dir = inside ? -1.0 : 1.0;
	bool hit = false;

	for (int i = 0; i < MARCH_MAX_STEPS; ++i)
	{
		p = o + t * v;
		float dist = dir * map(p, mat);

		hit = abs(dist) < HIT_RATIO * t;

		if (hit || t > max_dist) break;

		t += dist * STEP_RATIO;
	}

	n = normal(p, mat);

	return hit;
}

float getVisibility(vec3 p0, vec3 p1, float k)
{
	vec3 v = normalize(p1 - p0);
	float t = 10.0f * MIN_DIST;
	float maxt = length(p1 - p0);
	float f = 1.0f;
	material mat;
	while (t < maxt)
	{
		float dist = map(p0 + v * t, mat);

		// A surface was hit before we reached p1
		if (dist < MIN_DIST)
			return 0.0f;

		// Shadow
		f = min(f, k * dist / t);

		t += dist;
	}

	return f;
}

// * Ambient occlusion. Check if there are objects nearby.
// * Parameters:
// *  p           Location of the intersection
// *  n           Normal of the surface at the intersection point
// * Returns:
// *  darkness of the point clamped between 0 and 1
float ambientOcclusion(vec3 p, vec3 n)
{
	float stepSize = 0.01f;
	float t = stepSize;
	float occlusion = 0.0f;
	material mat;
	for (int i = 0; i < 10; ++i)
	{
		float dist = map(p + n * t, mat);
		occlusion += t - dist;
		t += stepSize;
	}

	return clamp(occlusion, 0, 1);
}

// * Soft shadow light intensity
// * Parameters:
// *  p           Location of the intersection
// *  n           Normal of the surface at the intersection point
// *  lightPos	  Location of light
// *  lightColor  Color of the light
// *  ambient     Ambient color
// * Returns:
// *  color of the point
vec4 lightIntensity(vec3 p, vec3 normal, vec3 lightPos, vec4 lightColor, vec4 ambient)
{
	float intensity = 0.0f;
	float vis = getVisibility(p, lightPos, 32);
	if (vis > 0.0f)
	{
		vec3 lightDirection = normalize(lightPos - p);
		intensity = clamp(dot(normal, lightDirection), 0, 1) * vis;
	}

	return lightColor * intensity + ambient * (1.0f - intensity);
}


/* Calculates the color of the pixel, based on view ray origin and direction.
 *
 * Parameters:
 *  o   Origin of the view ray
 *  v   Direction of the view ray
 *
 * Returns:
 *  Color of the pixel.
 */
vec3 render(vec3 o, vec3 v)
{
	// This lamp is positioned at the hole in the roof.
	vec3 lampPos = vec3(0.0, 2.0, 3.0);

	vec3 p, n;
	material mat;

	// Compute intersection point along the view ray.
	if (!intersect(o, v, MAX_DIST, p, n, mat, false)) {
		// Ray did not intersect, return color of the sky.
		return vec3(0.0, 0.4, 0.4);
	}

	// ambient
	float ambientStrength = 0.5;
	vec3 ambientColor = vec3(0.15, 0.2f, 0.32f);
	vec3 ambient = ambientStrength * ambientColor;
	vec4 ambientMatrix = vec4(ambient.x, ambient.y, ambient.z, 1.0);

	vec4 lampCol = vec4(1.0f, 1.0f, 1.0f, 1.0f);
	// Diffuse lighting
	vec4 diffuse = (lightIntensity(p, n, lampPos, lampCol, ambientMatrix)) / 2.0f;



	// specular
	vec3 norm = normalize(n);
	vec3 lightDir = normalize(lampPos - p);
	float specularStrength = 1.0;
	vec3 viewDir = normalize(o - p);
	vec3 reflectDir = reflect(-lightDir, norm);
	float spec = pow(max(dot(viewDir, reflectDir), 0.0), 32.0);
	vec3 specular = specularStrength * spec * vec3(0.070, 0.910, 0.354);

	vec3 result = (ambient + vec3(diffuse.x, diffuse.y, diffuse.z) + specular) * mat.color.rgb;

	// Add ambient occlusion
	float ao = ambientOcclusion(p, n);
	result = result * (1.0f - ao);

	return result;
}

// 4 x AntiAliasing
vec3 antiAlias(vec3 o, vec3 v) {
	vec2 offset = vec2(1.0) / (u_resolution * 2.0);
	vec3 v0 = normalize(u_cameraForward * u_focalLength + u_cameraRight * (uv.x - offset.x) * u_aspectRatio + u_cameraUp * uv.y);
	vec3 v1 = normalize(u_cameraForward * u_focalLength + u_cameraRight * (uv.x + offset.x) * u_aspectRatio + u_cameraUp * uv.y);
	vec3 v2 = normalize(u_cameraForward * u_focalLength + u_cameraRight * uv.x * u_aspectRatio + u_cameraUp * (uv.y - offset.y));
	vec3 v3 = normalize(u_cameraForward * u_focalLength + u_cameraRight * uv.x * u_aspectRatio + u_cameraUp * (uv.y + offset.y));

	vec3 antiAliasedColor = (render(o, v0) + render(o, v1) + render(o, v2) + render(o, v3)) / 4.0;

	return antiAliasedColor;
}

void main()
{
	vec3 o = u_cameraPosition;
	vec3 v = normalize(u_cameraForward * u_focalLength + u_cameraRight * uv.x * u_aspectRatio + u_cameraUp * uv.y);

	outColor = vec4(antiAlias(o, v), 1.0);
}
