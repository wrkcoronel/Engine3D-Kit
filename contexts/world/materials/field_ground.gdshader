shader_type spatial;
render_mode diffuse_burley, specular_disabled;

uniform vec3 soil_color : source_color = vec3(0.03, 0.04, 0.025);
uniform vec3 straw_color : source_color = vec3(0.4, 0.3, 0.1);
uniform vec3 straw_dark_color : source_color = vec3(0.25, 0.2, 0.07);
uniform float carpet_start = 30.0;
uniform float carpet_full = 80.0;

varying vec3 world_position;

float hash12(vec2 position) {
	vec3 mixed = fract(vec3(position.xyx) * 0.1031);
	mixed += dot(mixed, mixed.yzx + 33.33);
	return fract((mixed.x + mixed.y) * mixed.z);
}

float value_noise(vec2 position) {
	vec2 cell = floor(position);
	vec2 local = fract(position);
	vec2 smooth_local = local * local * (3.0 - 2.0 * local);
	float bottom = mix(hash12(cell), hash12(cell + vec2(1.0, 0.0)), smooth_local.x);
	float top = mix(hash12(cell + vec2(0.0, 1.0)), hash12(cell + vec2(1.0, 1.0)), smooth_local.x);
	return mix(bottom, top, smooth_local.y);
}

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	float distance_to_camera = distance(world_position, CAMERA_POSITION_WORLD);
	float far_amount = smoothstep(carpet_start, carpet_full, distance_to_camera);
	float fine_noise = value_noise(world_position.xz * 0.6);
	float broad_noise = value_noise(world_position.xz * 0.04);
	float mix_amount = clamp(fine_noise * 0.5 + broad_noise * 0.9, 0.0, 1.0);
	vec3 carpet = mix(straw_dark_color, straw_color, mix_amount);
	ALBEDO = mix(soil_color, carpet, far_amount);
	ROUGHNESS = 1.0;
}
