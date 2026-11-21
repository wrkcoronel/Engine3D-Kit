shader_type spatial;
render_mode cull_disabled, diffuse_burley, specular_disabled;

uniform vec3 tint : source_color = vec3(0.6, 0.6, 0.65);
uniform float building_seed = 0.0;
uniform vec2 window_period = vec2(3.4, 3.6);
uniform vec2 window_size = vec2(1.7, 2.0);
uniform float hole_chance = 0.85;
uniform float first_window_height = 1.0;
uniform vec3 rust_color : source_color = vec3(0.3, 0.14, 0.07);

varying vec3 world_position;
varying vec3 world_normal;

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

float fbm(vec2 position) {
	float total = 0.0;
	float amplitude = 0.5;
	for (int octave = 0; octave < 4; octave++) {
		total += value_noise(position) * amplitude;
		position *= 2.03;
		amplitude *= 0.5;
	}
	return total;
}

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	if (COLOR.a < 0.5) {
		float rust_noise = value_noise(world_position.xy * 20.0 + world_position.zy * 7.0);
		ALBEDO = rust_color * (0.6 + 0.6 * rust_noise);
		ROUGHNESS = 0.7;
	} else {
		bool is_wall_face = abs(world_normal.y) < 0.5;
		float along_wall = world_position.x;
		if (abs(world_normal.x) > abs(world_normal.z)) {
			along_wall = world_position.z;
		}
		vec2 window_grid = vec2(along_wall / window_period.x, (world_position.y - first_window_height) / window_period.y);
		vec2 window_cell = floor(window_grid) + building_seed;
		vec2 meters_from_center = (fract(window_grid) - 0.5) * window_period;
		float cell_roll = hash12(window_cell);
		float blast_roll = hash12(window_cell * 1.7 + 3.1);
		vec2 half_window = window_size * 0.5 * (1.0 + 0.6 * step(0.9, blast_roll));
		bool inside_window = abs(meters_from_center.x) < half_window.x && abs(meters_from_center.y) < half_window.y;
		bool has_hole = cell_roll < hole_chance && world_position.y > first_window_height;
		if (is_wall_face && inside_window && has_hole) {
			discard;
		}

		float blotches = fbm(world_position.xz * 0.35 + world_position.y * 0.2);
		vec3 color = tint * (0.7 + 0.5 * blotches);

		float streaks = fbm(vec2(along_wall * 3.0, world_position.y * 0.15));
		color *= 1.0 - 0.5 * smoothstep(0.55, 0.9, streaks);

		float meters_above_window = meters_from_center.y - half_window.y;
		float soot = 0.0;
		if (is_wall_face && has_hole && meters_above_window > 0.0) {
			soot = 1.0 - smoothstep(0.0, 2.2, meters_above_window);
		}
		color *= 1.0 - 0.85 * soot;

		float crack_noise = fbm(vec2(along_wall, world_position.y) * 0.9 + world_position.zx * 0.2);
		float crack = 1.0 - smoothstep(0.0, 0.02, abs(crack_noise - 0.5));
		color *= 1.0 - 0.6 * crack;

		color *= mix(0.45, 1.0, smoothstep(0.0, 3.5, world_position.y));
		if (!FRONT_FACING) {
			color *= 0.5;
		}
		ALBEDO = color;
		ROUGHNESS = 1.0;
	}
}
