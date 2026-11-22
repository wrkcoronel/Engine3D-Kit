shader_type canvas_item;

uniform float distortion_amount : hint_range(0.0, 1.0) = 0.0;
uniform float flash_amount : hint_range(0.0, 1.0) = 0.0;

float hash12(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

void fragment() {
	vec2 centered = UV - vec2(0.5);
	float radius = length(centered) * 1.45;
	float vignette = smoothstep(0.35, 1.05, radius);

	float t = floor(TIME * 24.0);
	float grain = hash12(floor(UV * 320.0) + vec2(t, t * 1.7));
	float band = step(0.88, hash12(vec2(floor(UV.y * 45.0), t)));
	float scan = sin(UV.y * 540.0 + TIME * 30.0) * 0.5 + 0.5;

	float intensity = clamp(distortion_amount + flash_amount * 0.85, 0.0, 1.0);
	vec3 tint = vec3(0.02, 0.025, 0.04);
	tint += vec3(0.45, 0.5, 0.62) * grain * (0.35 + flash_amount * 0.65);
	tint += vec3(0.7, 0.75, 0.85) * band * intensity * 0.45;
	tint *= 0.8 + 0.2 * scan;

	float alpha = (vignette * 0.72 + grain * 0.22 + band * 0.28) * intensity;
	alpha += flash_amount * 0.42;
	COLOR = vec4(tint, clamp(alpha, 0.0, 0.82));
}
