shader_type spatial;
render_mode blend_mix, cull_disabled, depth_draw_opaque;
// Falling water: streaks of white foam running down over blue-green water,
// each column at its own speed, fading out at the sheet's sides. UV.y counts
// metres down the sheet.

uniform vec3 water : source_color = vec3(0.45, 0.68, 0.76);
uniform vec3 foam : source_color = vec3(0.94, 0.97, 1.0);
uniform float speed = 6.0;

float hash(float n) {
	return fract(sin(n * 12.9898) * 43758.5453);
}

void fragment() {
	float column = floor(UV.x * 28.0);
	float rate = speed * (0.75 + 0.5 * hash(column));
	float streak = fract(UV.y * (0.35 + 0.2 * hash(column + 7.0)) - TIME * rate * 0.35 + hash(column + 3.0));
	float white = smoothstep(0.35, 0.95, streak);
	ALBEDO = mix(water, foam, clamp(0.35 + 0.65 * white, 0.0, 1.0));
	ROUGHNESS = 0.25;
	float sides = smoothstep(0.0, 0.12, UV.x) * smoothstep(1.0, 0.88, UV.x);
	ALPHA = clamp((0.72 + 0.25 * white) * sides, 0.0, 1.0);
}
