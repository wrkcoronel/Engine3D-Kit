shader_type sky;

uniform vec3 zenith_color : source_color = vec3(0.002, 0.004, 0.014);
uniform vec3 horizon_color : source_color = vec3(0.012, 0.025, 0.06);
uniform vec3 glow_color : source_color = vec3(1.0, 0.4, 0.1);
uniform float glow_strength = 0.0;
uniform float star_grid_scale = 50.0;
uniform float star_chance = 0.35;
uniform float star_brightness = 3.0;
uniform vec3 disc_color : source_color = vec3(0.8, 0.88, 1.0);
uniform float disc_radius = 0.035;
uniform float disc_brightness = 4.0;
uniform float disc_halo_brightness = 0.35;
uniform float disc_halo_falloff = 14.0;
uniform float disc_craters = 1.0;

float hash13(vec3 position) {
	vec3 mixed = fract(position * 0.1031);
	mixed += dot(mixed, mixed.zyx + 31.32);
	return fract((mixed.x + mixed.y) * mixed.z);
}

float star_intensity(vec3 direction) {
	vec3 scaled_direction = direction * star_grid_scale;
	vec3 cell = floor(scaled_direction);
	vec3 position_in_cell = scaled_direction - cell;
	float presence = hash13(cell);
	if (presence > star_chance) {
		return 0.0;
	}
	vec3 star_position = vec3(hash13(cell + 17.0), hash13(cell + 31.0), hash13(cell + 53.0));
	star_position = star_position * 0.6 + 0.2;
	float star_size = mix(0.08, 0.25, hash13(cell + 7.0));
	float distance_to_star = length(position_in_cell - star_position);
	float disc = smoothstep(star_size, 0.0, distance_to_star);
	float twinkle_speed = 1.5 + presence * 20.0;
	float twinkle = 0.75 + 0.25 * sin(TIME * twinkle_speed + presence * 100.0);
	float base_brightness = 0.3 + 0.7 * hash13(cell + 3.0);
	return disc * twinkle * base_brightness;
}

float disc_surface(vec3 direction, vec3 disc_direction) {
	vec3 side = normalize(cross(disc_direction, vec3(0.0, 1.0, 0.0)));
	vec3 up = cross(side, disc_direction);
	vec2 local = vec2(dot(direction, side), dot(direction, up)) / disc_radius;
	float patches = sin(local.x * 5.0 + 1.3) * sin(local.y * 4.0 - 0.7);
	float fine = sin(local.x * 13.0) * sin(local.y * 11.0 + 2.0);
	float craters = 0.1 * patches + 0.05 * fine;
	return 0.85 + craters * disc_craters + 0.15 * (1.0 - disc_craters);
}

vec3 horizon_glow(vec3 eye_direction, vec3 disc_direction) {
	vec3 sun_flat = normalize(vec3(disc_direction.x, 0.0001, disc_direction.z));
	vec3 eye_flat = normalize(vec3(eye_direction.x, 0.0001, eye_direction.z));
	float toward_sun = max(dot(sun_flat, eye_flat), 0.0);
	float low_in_sky = exp(-max(eye_direction.y, 0.0) * 4.0);
	return glow_color * pow(toward_sun, 3.0) * low_in_sky * glow_strength;
}

void sky() {
	float elevation = EYEDIR.y;
	float upward = pow(clamp(elevation, 0.0, 1.0), 0.45);
	vec3 color = mix(horizon_color, zenith_color, upward);
	color *= mix(0.4, 1.0, smoothstep(-0.2, 0.0, elevation));

	vec3 disc_direction = LIGHT0_DIRECTION;
	color += horizon_glow(EYEDIR, disc_direction);

	float disc_angle = acos(clamp(dot(EYEDIR, disc_direction), -1.0, 1.0));
	float halo = exp(-disc_angle * disc_halo_falloff) * disc_halo_brightness;
	float disc = smoothstep(disc_radius + 0.002, disc_radius - 0.002, disc_angle);

	float horizon_fade = smoothstep(0.0, 0.1, elevation);
	float stars = star_intensity(EYEDIR) * horizon_fade;
	stars *= 1.0 - clamp(halo * 4.0 + disc, 0.0, 1.0);
	color += vec3(0.8, 0.9, 1.0) * stars * star_brightness;

	color += disc_color * halo;
	vec3 disc_pixel = disc_color * disc_brightness * disc_surface(EYEDIR, disc_direction);
	color = mix(color, disc_pixel, disc);
	COLOR = color;
}
