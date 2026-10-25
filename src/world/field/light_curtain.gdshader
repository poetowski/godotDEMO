shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, shadows_disabled;

// A soft sheet of light rising from a grid line and fading toward the sky.
// Vertex colour alpha is 1 at the ground and 0 at the top. Faint bands drift
// slowly upward. The sheet fades out near the camera, so walking through it
// never blinds the view, and far away, so distant lines don't pile up into haze.

uniform vec3 color : source_color = vec3(0.55, 0.9, 1.0);
uniform float intensity = 0.25;
// Most of the light hugs the ground; higher values thin the top out faster.
uniform float falloff = 3.0;
uniform float near_fade_start = 3.0;
uniform float near_fade_end = 7.0;
uniform float far_fade_start = 15.0;
uniform float far_fade_end = 40.0;
uniform float drift_speed = 0.8;

void fragment() {
	// Interpolation can dip just below zero at the top edge, and pow() of a
	// negative number is NaN, which bloom smears across the screen.
	float rise = clamp(COLOR.a, 0.0, 1.0);
	float distance_to_camera = length(VERTEX);
	float fade = smoothstep(near_fade_start, near_fade_end, distance_to_camera)
		* (1.0 - smoothstep(far_fade_start, far_fade_end, distance_to_camera));
	float bands = 0.8 + 0.2 * sin((1.0 - rise) * 14.0 - TIME * drift_speed);
	ALBEDO = color;
	ALPHA = pow(rise, falloff) * intensity * fade * bands;
}
