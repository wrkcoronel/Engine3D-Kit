shader_type spatial;
render_mode cull_disabled, diffuse_burley, specular_disabled;

uniform float wind_strength = 0.1;
uniform float wind_speed = 1.3;
uniform float wind_wavelength = 9.0;
uniform vec2 wind_direction = vec2(1.0, 0.4);
uniform float flutter_strength = 0.015;
uniform float tone_variation = 0.25;
uniform float height_for_full_bend = 1.1;

uniform mat4 vehicle_world_to_local = mat4(1.0);
uniform vec2 vehicle_half_size = vec2(1.0, 2.0);
uniform float vehicle_clear_margin = 0.4;
uniform float vehicle_active = 0.0;
uniform float flattened_height = 0.03;
uniform sampler2D trample_map : hint_default_black, filter_linear;
uniform vec2 trample_origin = vec2(-20.0, -20.0);
uniform float trample_size = 40.0;
uniform float trampled_height = 0.12;
uniform float fade_start_distance = 29.0;
uniform float fade_end_distance = 43.0;

varying float clump_tone;

float hash12(vec2 position) {
	vec3 mixed = fract(vec3(position.xyx) * 0.1031);
	mixed += dot(mixed, mixed.yzx + 33.33);
	return fract((mixed.x + mixed.y) * mixed.z);
}

float vehicle_flatten(vec3 world_position) {
	vec3 local_position = (vehicle_world_to_local * vec4(world_position, 1.0)).xyz;
	vec2 outside_footprint = max(abs(local_position.xz) - vehicle_half_size, vec2(0.0));
	float distance_outside = length(outside_footprint);
	float flatten = 1.0 - smoothstep(0.0, vehicle_clear_margin, distance_outside);
	return flatten * vehicle_active;
}

float trample_amount(vec3 world_position) {
	vec2 map_uv = (world_position.xz - trample_origin) / trample_size;
	return textureLod(trample_map, map_uv, 0.0).r;
}

void vertex() {
	vec3 clump_origin = MODEL_MATRIX[3].xyz;
	clump_tone = hash12(clump_origin.xz);

	float bend_weight = clamp(VERTEX.y / height_for_full_bend, 0.0, 1.0);
	bend_weight = bend_weight * bend_weight;

	vec2 wind_axis = normalize(wind_direction);
	float travel = dot(clump_origin.xz, wind_axis) / wind_wavelength;
	float wave = sin(TIME * wind_speed - travel * TAU);
	float gust = sin(TIME * wind_speed * 0.31 - travel * 1.7 + clump_tone * 6.0);
	float flutter = sin(TIME * 4.0 + clump_tone * 40.0 + VERTEX.y * 6.0);
	float sway = (wave * 0.6 + gust * 0.4) * wind_strength + flutter * flutter_strength;

	vec3 world_offset = vec3(wind_axis.x, 0.0, wind_axis.y) * sway * bend_weight;
	vec3 local_offset = inverse(mat3(MODEL_MATRIX)) * world_offset;
	VERTEX += local_offset;

	vec3 bent_world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float under_vehicle_height = mix(1.0, flattened_height, vehicle_flatten(bent_world_position));
	float trail_height = mix(1.0, trampled_height, trample_amount(bent_world_position));
	float camera_distance = length(bent_world_position.xz - CAMERA_POSITION_WORLD.xz);
	float distance_height = 1.0 - smoothstep(fade_start_distance, fade_end_distance, camera_distance);
	VERTEX.y *= min(min(under_vehicle_height, trail_height), distance_height);
}

void fragment() {
	float tone = mix(1.0 - tone_variation, 1.0 + tone_variation, clump_tone);
	ALBEDO = COLOR.rgb * tone;
	ROUGHNESS = 0.9;
	NORMAL = normalize((VIEW_MATRIX * vec4(0.0, 1.0, 0.0, 0.0)).xyz);
}
