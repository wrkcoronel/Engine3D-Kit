shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, unshaded;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
uniform float glitch_intensity : hint_range(0.0, 1.0) = 0.25;
uniform float visibility_amount : hint_range(0.0, 1.0) = 1.0;
uniform float blur_strength : hint_range(0.0, 0.04) = 0.014;
uniform vec4 core_color : source_color = vec4(0.02, 0.02, 0.035, 1.0);
uniform vec4 rim_color : source_color = vec4(0.55, 0.62, 0.72, 1.0);

float hash12(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

void vertex() {
	float t = TIME;
	float slice = floor(VERTEX.y * 10.0 + t * 8.0);
	float pulse = step(0.84 - glitch_intensity * 0.35, hash12(vec2(slice, floor(t * 14.0))));
	float tear = (hash12(vec2(slice, t)) - 0.5) * 0.42 * (0.25 + glitch_intensity) * pulse;
	float breathe = sin(t * 3.1 + VERTEX.y * 4.5) * 0.03;
	float jitter = (hash12(vec2(VERTEX.y * 19.0, floor(t * 24.0))) - 0.5) * 0.045 * (0.4 + glitch_intensity);
	VERTEX.x += tear + breathe + jitter;
	VERTEX.z += (hash12(vec2(VERTEX.x * 13.0, floor(t * 20.0))) - 0.5) * 0.04 * (0.4 + glitch_intensity);
}

void fragment() {
	float ndotv = clamp(dot(normalize(NORMAL), normalize(VIEW)), 0.0, 1.0);
	float fresnel = pow(1.0 - ndotv, 2.2);
	float t = floor(TIME * 18.0);
	float noise = hash12(floor(SCREEN_UV * 160.0) + vec2(t, t * 0.37));
	float scan = sin(SCREEN_UV.y * 420.0 + TIME * 22.0) * 0.5 + 0.5;

	vec2 warp = vec2(
		(noise - 0.5) * blur_strength * (1.2 + glitch_intensity * 2.5),
		(scan - 0.5) * blur_strength * 0.8
	);
	vec2 uv = clamp(SCREEN_UV + warp, vec2(0.002), vec2(0.998));

	vec3 bg_center = texture(screen_texture, uv).rgb;
	vec3 bg_r = texture(screen_texture, clamp(uv + vec2(blur_strength * 0.7, 0.0), vec2(0.002), vec2(0.998))).rgb;
	vec3 bg_b = texture(screen_texture, clamp(uv - vec2(blur_strength * 0.7, 0.0), vec2(0.002), vec2(0.998))).rgb;
	vec3 bg_up = texture(screen_texture, clamp(uv + vec2(0.0, blur_strength * 0.6), vec2(0.002), vec2(0.998))).rgb;
	vec3 bg_dn = texture(screen_texture, clamp(uv - vec2(0.0, blur_strength * 0.6), vec2(0.002), vec2(0.998))).rgb;
	vec3 blurred_bg = (bg_center + vec3(bg_r.r, bg_center.g, bg_b.b) + bg_up + bg_dn) * 0.25;

	float core_mask = smoothstep(0.05, 0.75, ndotv);
	vec3 body_col = mix(blurred_bg * 0.55, core_color.rgb, core_mask * (0.78 + glitch_intensity * 0.18));
	body_col += rim_color.rgb * fresnel * (0.28 + 0.35 * noise) * (0.6 + glitch_intensity);
	body_col += vec3(noise - 0.5) * (0.08 + glitch_intensity * 0.18);

	float edge_fade = smoothstep(0.02, 0.38, ndotv);
	float flicker = 0.78 + 0.22 * hash12(vec2(floor(TIME * 15.0), 7.0));
	ALBEDO = clamp(body_col, vec3(0.0), vec3(1.0));
	ALPHA = clamp(edge_fade * visibility_amount * flicker * (0.72 + 0.24 * core_mask), 0.0, 0.96);
}
