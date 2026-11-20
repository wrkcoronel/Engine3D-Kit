shader_type canvas_item;
render_mode unshaded;

void fragment() {
	vec2 screen_size = 1.0 / SCREEN_PIXEL_SIZE;
	float shortest_side = min(screen_size.x, screen_size.y);
	vec2 from_center = (SCREEN_UV - vec2(0.5)) * screen_size / shortest_side;
	float distance_to_center = length(from_center);
	float outside_lens = smoothstep(0.425, 0.435, distance_to_center);
	float line_width = 1.2 / shortest_side;
	float nearest_line = min(abs(from_center.x), abs(from_center.y));
	float reticle = 1.0 - smoothstep(line_width, line_width * 2.0, nearest_line);
	float ring = 1.0 - smoothstep(0.003, 0.005, abs(distance_to_center - 0.421));
	float alpha = max(outside_lens, max(reticle * 0.9, ring));
	COLOR = vec4(vec3(0.015), alpha);
}
