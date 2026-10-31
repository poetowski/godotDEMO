shader_type spatial;
render_mode blend_mix, cull_front, depth_test_disabled, depth_draw_never, shadows_disabled;

// Fog filling a polygon, drawn on the far faces of its prism: each pixel walks its
// ray from the camera to where it leaves the prism or meets the ground, adding up
// how much fog it passes. How thick the fog is depends on how far inside the polygon
// a point lies (`distance_map`, metres): thin for the first sectors, then thickening,
// and its top rises the same way, so it starts low at the rim and banks up behind.
// It's also thick near the world's edge, wherever the line runs, to hide the edge.
// Lit from above, so it darkens with the night.

uniform sampler2D depth_texture : hint_depth_texture, filter_linear_mipmap, repeat_disable;
uniform sampler2D distance_map : filter_linear, repeat_disable;
uniform sampler2D billows : repeat_enable, filter_linear_mipmap;
// The map's west, north, width and depth, in world x and z.
uniform vec4 map_rect = vec4(0.0, 0.0, 1.0, 1.0);
uniform vec3 mist : source_color = vec3(0.92, 0.94, 0.96);
// Fog per metre of ray: in the first sectors, then where it's thickest, and the
// metres into the polygon where the one gives way to the other.
uniform float thin = 0.008;
uniform float thick = 0.085;
uniform float thin_until = 28.0;
uniform float thick_from = 88.0;
// The fog's top at the line and far inside it, and how soft it is.
uniform float top_at_line = -8.0;
uniform float top_far = 32.0;
uniform float top_rise = 90.0;
uniform float top_soft = 14.0;
uniform float drift = 0.004;
// The world's west, north, east and south, in world x and z, and how many metres
// inside them the fog is already at its thickest.
uniform vec4 world_edges = vec4(0.0, 0.0, 1.0, 1.0);
uniform float edge_metres = 45.0;
// Metres of ray walked at most; past it the fog is solid anyway.
uniform float longest = 520.0;

const int STEPS = 26;

varying vec3 world_position;

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec3 from = CAMERA_POSITION_WORLD;
	vec3 ray = world_position - from;
	float leaves = length(ray);
	ray /= leaves;
	float depth = textureLod(depth_texture, SCREEN_UV, 0.0).r;
	float ground = 1e9;
	if (depth > 1e-6) {
		vec4 behind = INV_PROJECTION_MATRIX * vec4(SCREEN_UV * 2.0 - 1.0, depth, 1.0);
		ground = length(behind.xyz / behind.w);
	}
	float end = min(min(leaves, ground), longest);
	float step_size = end / float(STEPS);
	// A different start per pixel turns banding into fine grain.
	float jitter = fract(52.9829189 * fract(dot(FRAGCOORD.xy, vec2(0.06711056, 0.00583715))));
	float fog = 0.0;
	for (int k = 0; k < STEPS; k++) {
		vec3 at = from + ray * (float(k) + jitter) * step_size;
		float inside = texture(distance_map, (at.xz - map_rect.xy) / map_rect.zw).r;
		if (inside <= 0.0) {
			continue;
		}
		float to_edge = min(min(at.x - world_edges.x, world_edges.z - at.x), min(at.z - world_edges.y, world_edges.w - at.z));
		float edge = (1.0 - smoothstep(0.0, edge_metres, to_edge)) * smoothstep(0.0, 40.0, inside);
		float top = mix(top_at_line, top_far, max(clamp(inside / top_rise, 0.0, 1.0), edge));
		float billow = texture(billows, at.xz * 0.0045 + vec2(TIME * drift, at.y * 0.006)).r;
		float under = clamp((top + (billow - 0.5) * 16.0 - at.y) / top_soft, 0.0, 1.0);
		float density = mix(thin, thick, max(smoothstep(thin_until, thick_from, inside), edge));
		fog += density * under * (0.55 + 0.9 * billow) * step_size;
		if (fog > 5.0) {
			break;
		}
	}
	ALBEDO = mist;
	NORMAL = (VIEW_MATRIX * vec4(0.0, 1.0, 0.0, 0.0)).xyz;
	ROUGHNESS = 1.0;
	SPECULAR = 0.0;
	ALPHA = 1.0 - exp(-fog);
}
