shader_type spatial;
render_mode cull_disabled;

// Grass tufts drawn as a MultiMesh: blades fade from the field's grass at the
// root to a sunlit tip and sway in a gentle, slow wind. UV.y runs from 0 at the
// roots to 1 at the tips; the MultiMesh instance colour tints each tuft.
// Blades are lit as if they faced the sky, so they match the ground.

uniform vec3 root_color : source_color = vec3(0.25, 0.43, 0.16);
uniform vec3 tip_color : source_color = vec3(0.5, 0.66, 0.29);
uniform vec2 wind_direction = vec2(0.8, 0.6);
uniform float sway = 0.045;
uniform float sway_speed = 1.1;

varying float height_fraction;

// Interpolated colours can overshoot below 0 at triangle edges (MSAA shades
// pixel centres outside the triangle), and pow() of a negative is NaN, which
// bloom spreads into a white blob. Hence the max().
vec3 srgb_to_linear(vec3 c) {
	c = max(c, vec3(0.0));
	return mix(c / 12.92, pow((c + 0.055) / 1.055, vec3(2.4)), step(0.04045, c));
}

void vertex() {
	height_fraction = UV.y;
	vec3 origin = MODEL_MATRIX[3].xyz;
	float phase = dot(origin.xz, vec2(0.31, 0.23));
	float gust = sin(TIME * sway_speed + phase) * 0.7 + sin(TIME * sway_speed * 2.1 + phase * 1.9) * 0.3;
	vec3 wind = vec3(wind_direction.x, 0.0, wind_direction.y) * gust * sway * UV.y * UV.y;
	VERTEX += (inverse(MODEL_MATRIX) * vec4(wind, 0.0)).xyz;
}

void fragment() {
	ALBEDO = mix(root_color, tip_color, height_fraction) * srgb_to_linear(COLOR.rgb);
	ROUGHNESS = 0.9;
	NORMAL = normalize((VIEW_MATRIX * vec4(0.0, 1.0, 0.0, 0.0)).xyz);
	BACKLIGHT = vec3(0.18, 0.22, 0.08) * height_fraction;
}
