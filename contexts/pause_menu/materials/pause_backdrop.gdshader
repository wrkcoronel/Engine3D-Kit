shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear_mipmap;
uniform float settings_mode : hint_range(0.0, 1.0) = 0.0;

vec3 sample_blurred_screen(vec2 uv, vec2 pixel_size, float blur_radius) {
	if (blur_radius <= 0.05) {
		return texture(screen_texture, uv).rgb;
	}
	float lod = blur_radius * 0.6;
	vec2 step_uv = pixel_size * blur_radius * 1.4;
	vec3 sum = textureLod(screen_texture, uv, lod).rgb * 0.24;
	sum += textureLod(screen_texture, uv + vec2(step_uv.x, 0.0), lod).rgb * 0.12;
	sum += textureLod(screen_texture, uv - vec2(step_uv.x, 0.0), lod).rgb * 0.12;
	sum += textureLod(screen_texture, uv + vec2(0.0, step_uv.y), lod).rgb * 0.12;
	sum += textureLod(screen_texture, uv - vec2(0.0, step_uv.y), lod).rgb * 0.12;
	sum += textureLod(screen_texture, uv + vec2(step_uv.x, step_uv.y), lod).rgb * 0.07;
	sum += textureLod(screen_texture, uv + vec2(-step_uv.x, step_uv.y), lod).rgb * 0.07;
	sum += textureLod(screen_texture, uv + vec2(step_uv.x, -step_uv.y), lod).rgb * 0.07;
	sum += textureLod(screen_texture, uv + vec2(-step_uv.x, -step_uv.y), lod).rgb * 0.07;
	return sum;
}

void fragment() {
	float left_gradient = 1.0 - smoothstep(0.10, 0.46, SCREEN_UV.x);
	float pause_darkness = left_gradient * 0.72;
	float pause_blur = left_gradient * 2.2;

	vec2 center_offset = (SCREEN_UV - vec2(0.50, 0.44)) * vec2(1.15, 1.45);
	float center_distance = length(center_offset);
	float center_gradient = 1.0 - smoothstep(0.28, 0.78, center_distance);
	float settings_darkness = center_gradient * 0.74;
	float settings_blur = center_gradient * 2.4;

	float darkness = mix(pause_darkness, settings_darkness, settings_mode);
	float blur_radius = mix(pause_blur, settings_blur, settings_mode);

	vec3 scene_color = sample_blurred_screen(SCREEN_UV, SCREEN_PIXEL_SIZE, blur_radius);
	vec3 veil_tint = vec3(0.015, 0.018, 0.024);
	vec3 final_color = mix(scene_color, veil_tint, darkness);

	COLOR = vec4(final_color, 1.0);
}
