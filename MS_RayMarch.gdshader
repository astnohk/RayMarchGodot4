shader_type canvas_item;

#define RAY_MARCHING_DISTANCE_EPSILON 1.0E-6
#define NUM_SHAPE_MAX 16
#define MAX_ITER_MARCHING 314

#define SHAPE_TYPE_WALL 0
#define SHAPE_TYPE_SPHERE 1
#define SHAPE_TYPE_CYLINDER 2
#define SHAPE_TYPE_TORUS 3

#define SHAPE_OPERATION_NONE 0
#define SHAPE_OPERATION_ASSIGN 1
#define SHAPE_OPERATION_UNION 2
#define SHAPE_OPERATION_INTERSECTION 3
#define SHAPE_OPERATION_DIFF 4

varying vec3 textureCoord;

void vertex()
{
	//VERTEX = VERTEX;
	textureCoord.xy = 2.0 * vec2(UV.x, 1.0 - UV.y) - vec2(1.0);
	textureCoord.z = 1.0;
}

struct TraceData
{
	vec3 pos;
	vec3 dir;
	vec3 col;
	vec3 reflection;
};

const vec3 dx = vec3(1.0E-5, 0.0, 0.0);
const vec3 dy = vec3(0.0, 1.0E-5, 0.0);
const vec3 dz = vec3(0.0, 0.0, 1.0E-5);

uniform float seed;
uniform vec3 cameraPosition;
uniform float max_iter;
uniform float focus;
uniform float f_val;

// Using struct makes compiling time very long
uniform int numberOfShapes;
uniform ivec4 shape_type[NUM_SHAPE_MAX];
uniform ivec4 shape_ope[NUM_SHAPE_MAX];
uniform mat4 shape_va[NUM_SHAPE_MAX];
uniform mat4 shape_vb[NUM_SHAPE_MAX];
uniform vec4 shape_fa[NUM_SHAPE_MAX];
uniform vec4 shape_fb[NUM_SHAPE_MAX];
uniform vec3 shape_col[NUM_SHAPE_MAX];
uniform vec3 shape_ref[NUM_SHAPE_MAX];
uniform float shape_rough[NUM_SHAPE_MAX];
uniform float shape_f0[NUM_SHAPE_MAX]; // Fresnel reflection coefficient at perpendicular incident
uniform float shape_cr[NUM_SHAPE_MAX]; // crystal

const float exposure = 1.08;
//const float no_fog = 0.9; // probability of rays not hit particle in the air

float random(vec2 v)
{
	return fract(sin(dot(v, vec2(12.9898, 78.233))) * 43758.5453);
}

float d_union(float shape0, float shape1)
{
	return min(shape0, shape1);
}

float d_intersection(float shape0, float shape1)
{
	return max(shape0, shape1);
}

// Calculate shape0 - shape1
// args:
//     shape0: distance of the base shape
//     shape1: distance of the subtract shape
float d_diff(float shape0, float shape1)
{
	return max(shape0, -shape1);
}

float d_crystal(float shape)
{
	return abs(shape);
}

// args:
//     pos: position of center of the wall
//     dir: direction of surface norm of the wall (should be normalized)
//     ray: current position of the ray
float d_plane(vec3 pos, vec3 dir, vec3 pos_ray)
{
	return dot(pos_ray - pos, normalize(dir));
}

// args:
//     pos: position of center of the sphere
//     ray: current position of the ray
float d_sphere(vec3 pos, float r, vec3 pos_ray)
{
	return length(pos - pos_ray) - r;
}

// args:
//     sp: position of start edge of the cylinder
//     ep: position of end edge of the cylinder
//     ray: current position of the ray
float d_cylinder(vec3 sp, vec3 ep, float r, vec3 pos_ray)
{
	vec3 mid = (sp + ep) * 0.5;
	float lh = length(ep - mid);
	vec3 a = normalize(ep - sp);
	float v = dot(a, pos_ray - mid);
	vec3 n = normalize(pos_ray - mid - v * a);
	float d = mix(
		length(pos_ray - mid - v * a) - r,
		mix(max(dot(sp - pos_ray, a), dot(pos_ray - ep, a)),
		    min(length(sp + n * r - pos_ray), length(pos_ray - ep - n * r)),
		    step(r, dot(pos_ray - sp, n))),
		step(lh, abs(v)));
	return d;
}

// args:
//     c: position of center of the torus
//     a: axis of the torus
//     ra: radius of the torus center
//     rb: radius of the torus tube
//     ray: current position of the ray
float d_torus(vec3 c, vec3 a, float ra, float rb, vec3 pos_ray)
{
	a = normalize(a);
	vec3 p = pos_ray - c;
	vec3 p_r = normalize(p - dot(p, a) * a);
	return length(p - ra * p_r) - rb;
}

float d_shape(int shape, vec3 pos)
{
	float d;
	float d_tmp;
	// Original shape
	if (shape_ope[shape][0] == SHAPE_OPERATION_NONE)
	{
		// DO NOTHING
	}
	else if (shape_type[shape][0] == SHAPE_TYPE_WALL)
	{
		////
		// wall hit
		////
		d = d_plane(shape_va[shape][0].xyz, shape_vb[shape][0].xyz, pos);
	}
	else if (shape_type[shape][0] == SHAPE_TYPE_SPHERE)
	{
		////
		// sphere hit
		////
		d = d_sphere(shape_va[shape][0].xyz, shape_fa[shape][0], pos);
	}
	else if (shape_type[shape][0] == SHAPE_TYPE_CYLINDER)
	{
		////
		// cylinder hit
		////
		d = d_cylinder(shape_va[shape][0].xyz, shape_vb[shape][0].xyz, shape_fa[shape][0], pos);
	}
	else if (shape_type[shape][0] == SHAPE_TYPE_TORUS)
	{
		////
		// torus hit
		////
		d = d_torus(shape_va[shape][0].xyz, shape_vb[shape][0].xyz, shape_fa[shape][0], shape_fb[shape][0], pos);
	}
	// Logical operation
	for (int i = 1; i < 4; ++i)
	{
		if (shape_ope[shape][i] == SHAPE_OPERATION_NONE)
		{
			// DO NOTHING
		}
		else if (shape_type[shape][i] == SHAPE_TYPE_WALL)
		{
			////
			// wall hit
			////
			d_tmp = d_plane(
			    shape_va[shape][0].xyz + shape_va[shape][i].xyz,
			    shape_vb[shape][i].xyz,
			    pos);
		}
		else if (shape_type[shape][i] == SHAPE_TYPE_SPHERE)
		{
			////
			// sphere hit
			////
			d_tmp = d_sphere(
			    shape_va[shape][0].xyz + shape_va[shape][i].xyz,
			    shape_fa[shape][i],
			    pos);
		}
		else if (shape_type[shape][i] == SHAPE_TYPE_CYLINDER)
		{
			////
			// cylinder hit
			////
			d_tmp = d_cylinder(
			    shape_va[shape][0].xyz + shape_va[shape][i].xyz,
			    shape_vb[shape][i].xyz,
			    shape_fa[shape][i],
			    pos);
		}
		else if (shape_type[shape][i] == SHAPE_TYPE_TORUS)
		{
			////
			// torus hit
			////
			d_tmp = d_torus(
			    shape_va[shape][0].xyz + shape_va[shape][i].xyz,
			    shape_vb[shape][i].xyz,
			    shape_fa[shape][i],
			    shape_fb[shape][i],
			    pos);
		}
		// Logical operation
		// SHAPE_OPERATION_NONE do nothing
		if (shape_ope[shape][i] == SHAPE_OPERATION_ASSIGN)
		{
			d = d_tmp;
		}
		else if (shape_ope[shape][i] == SHAPE_OPERATION_UNION)
		{
			d = d_union(d, d_tmp);
		}
		else if (shape_ope[shape][i] == SHAPE_OPERATION_INTERSECTION)
		{
			d = d_intersection(d, d_tmp);
		}
		else if (shape_ope[shape][i] == SHAPE_OPERATION_DIFF)
		{
			d = d_diff(d, d_tmp);
		}
	}
	if (abs(shape_cr[shape]) > 1E-4)
	{
		d = d_crystal(d);
	}
	return d;
}

// args:
//     hit: the index of shape which the ray hits
vec3 getNormVec(TraceData ray, int hit)
{
	vec3 norm = vec3(
		d_shape(hit, ray.pos + dx) - d_shape(hit, ray.pos - dx),
		d_shape(hit, ray.pos + dy) - d_shape(hit, ray.pos - dy),
		d_shape(hit, ray.pos + dz) - d_shape(hit, ray.pos - dz));
	return normalize(norm);
}

// args:
//     origin: start point of ray
//     ray: direction of ray (should be normalized)
TraceData traceRay(TraceData ray, const float iter)
{
	for (int i = 0; i < MAX_ITER_MARCHING; ++i)
	{
		float d_min = 1E5;
		int hit = -1;
		for (int k = 0; k < min(numberOfShapes, NUM_SHAPE_MAX); ++k)
		{
			float d = d_shape(k, ray.pos);
			d_min = min(d, d_min);
			if (d < RAY_MARCHING_DISTANCE_EPSILON)
			{
				hit = k;
			}
		}
		// Forward ray
		ray.pos += ray.dir * d_min;
		// Add fog
		ray.col += vec3(0.03, 0.03, 0.06)
			* ray.reflection
			* log(1.0 + d_min)
			* abs(random(vec2(
				seed,
				ray.pos.x + ray.pos.y + ray.pos.z
			)));
		ray.reflection *= exp(-0.1 * d_min); // attenuation

		if (hit >= 0)
		{
			// Reflect
			vec3 norm = getNormVec(ray, hit);
			// Color
			//*
			ray.col = clamp(
				ray.col + ray.reflection * shape_col[hit],
				0.0,
				2.0);
			//*/
			//ray.col = vec3(0.5 + norm.x, 0.5 + norm.y, 0.0);
			//ray.col = vec3(0.5) + 0.5 * norm;
			//ray.col = vec3(d_min * 1e3);
			// Reflect the ray
			if (iter > 0.0 || shape_cr[hit] <= 0.0)
			{
				//ray.dir = reflect(ray.dir, norm);
				ray.dir = normalize(
					ray.dir - 2.0 * dot(ray.dir, norm) * norm);
				// reflection
				ray.reflection = ray.reflection * shape_ref[hit] * mix(
					dot(ray.dir, norm),
				    shape_f0[hit] + (1.0 - shape_f0[hit]) * pow(1.0 - dot(ray.dir, norm), 5.0),
				    step(1.0, iter));
			}
			else
			{
				float n = dot(ray.dir, norm);
				ray.dir = normalize((ray.dir - n * norm) * pow(shape_cr[hit], -sign(n)) + n * norm);
				// refraction
				ray.reflection = 0.99 * ray.reflection;
			}
			ray.pos += ray.dir * RAY_MARCHING_DISTANCE_EPSILON * 10.0;
		}
	}
	return ray;
}

#define BLUR_CIRCLE_RADIUS_COEFF 0.1
#define MULTI_PATH_RTX_BRIGHTNESS_CORRECTION_COEFF 1.25

void fragment()
{
	vec3 color = vec3(0.0);
	// First
	TraceData ray;
	vec3 start = cameraPosition + textureCoord / f_val;
	start.z = 0.0;
	ray.pos = start;
	ray.dir = normalize(focus * textureCoord - start);
	ray.col = vec3(0.0);
	ray.reflection = vec3(1.0);
	//// Marching
	ray = traceRay(ray, 0.0);
	//// Get color
	color += ray.col / max_iter * MULTI_PATH_RTX_BRIGHTNESS_CORRECTION_COEFF;
	// Second and later
	for (float iter = 1.0; iter < max_iter; iter += 1.0)
	{
		start = cameraPosition + textureCoord / f_val + vec3(
			BLUR_CIRCLE_RADIUS_COEFF / f_val * cos(PI * 2.0 * iter / max_iter),
			BLUR_CIRCLE_RADIUS_COEFF / f_val * sin(PI * 2.0 * iter / max_iter),
			0.0);
		start.z = 0.0;
		ray.pos = start;
		ray.dir = normalize(focus * textureCoord - start);
		ray.col = vec3(0.0);
		ray.reflection = vec3(1.0);
		// Marching
		ray = traceRay(ray, iter);
		// Get color
		color += ray.col / max_iter * MULTI_PATH_RTX_BRIGHTNESS_CORRECTION_COEFF;
	}
	COLOR = vec4(clamp(exposure * color, 0.0, 1.0), 1.0);
}

void light()
{
	// Called for every pixel for every light affecting the CanvasItem.
}
