shader_type spatial;
render_mode blend_mix, depth_draw_never, cull_back, specular_schlick_ggx;

// Flowing water. Each vertex carries its flow in COLOR.rg, where 0.5 is still
// and 0 or 1 is max_flow_speed metres per second along world x and z. Ripples
// and flecks of foam drift along the flow with the two-phase flow-map blend,
// so they keep moving without stretching. Shallow water turns clear, with a
// thin line of foam where it meets the banks and stones.

uniform vec3 deep_color : source_color = vec3(0.05, 0.25, 0.3);
uniform vec3 shallow_color : source_color = vec3(0.2, 0.5, 0.47);
uniform vec3 foam_color : source_color = vec3(0.9, 0.95, 0.95);
uniform float max_flow_speed = 1.0;
// Metres of depth at which the water reaches its full colour.
uniform float clarity_depth = 0.55;
uniform float foam_depth = 0.025;
uniform float ripple_size = 0.6;
uniform float ripple_strength = 0.05;
uniform float fleck_amount = 0.4;
uniform float cycle_seconds = 1.6;
uniform sampler2D depth_texture : hint_depth_texture, filter_linear_mipmap;

varying vec3 world_position;
varying vec2 flow;

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	flow = (COLOR.rg - 0.5) * 2.0 * max_flow_speed;
}

vec2 gradient(vec2 cell) {
	float angle = fract(sin(dot(cell, vec2(127.1, 311.7))) * 43758.5453) * 6.2831853;
	return vec2(cos(angle), sin(angle));
}

// Smooth gradient noise around 0.5.
float gradient_noise(vec2 p) {
	vec2 cell = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * f * (f * (f * 6.0 - 15.0) + 10.0);
	float a = dot(gradient(cell), f);
	float b = dot(gradient(cell + vec2(1.0, 0.0)), f - vec2(1.0, 0.0));
	float c = dot(gradient(cell + vec2(0.0, 1.0)), f - vec2(0.0, 1.0));
	float d = dot(gradient(cell + vec2(1.0, 1.0)), f - vec2(1.0, 1.0));
	return mix(mix(a, b, u.x), mix(c, d, u.x), u.y) + 0.5;
}

// Three turned octaves, so no grid shows through.
float ripples(vec2 p) {
	mat2 turn = mat2(vec2(0.8, 0.6), vec2(-0.6, 0.8));
	float height = gradient_noise(p) * 0.6;
	p = turn * p * 2.2 + 13.0;
	height += gradient_noise(p) * 0.28;
	p = turn * p * 2.2 + 7.0;
	return height + gradient_noise(p) * 0.12;
}

// A pattern at a point, carried downstream: two copies drift with the flow,
// each fading out before it resets.
float drifting(vec2 p, float scale, vec2 offset) {
	float phase0 = fract(TIME / cycle_seconds);
	float phase1 = fract(TIME / cycle_seconds + 0.5);
	float weight0 = 1.0 - abs(1.0 - 2.0 * phase0);
	float a = ripples((p - flow * phase0 * cycle_seconds) / scale + offset);
	float b = ripples((p - flow * phase1 * cycle_seconds) / scale + offset + vec2(0.37, 0.71));
	return mix(b, a, weight0);
}

float surface_height(vec2 p) {
	return drifting(p, ripple_size, vec2(0.0)) + gradient_noise(p * 1.8 + TIME * vec2(0.11, 0.07)) * 0.2;
}

void fragment() {
	vec2 p = world_position.xz;
	float step_size = 0.03;
	float h = surface_height(p);
	float slope_x = (surface_height(p + vec2(step_size, 0.0)) - h) / step_size;
	float slope_z = (surface_height(p + vec2(0.0, step_size)) - h) / step_size;
	vec3 world_normal = normalize(vec3(-slope_x * ripple_strength, 1.0, -slope_z * ripple_strength));
	NORMAL = normalize((VIEW_MATRIX * vec4(world_normal, 0.0)).xyz);

	// How deep the water is below this point, from the opaque scene behind it.
	float raw_depth = texture(depth_texture, SCREEN_UV).r;
	vec4 behind = INV_PROJECTION_MATRIX * vec4(SCREEN_UV * 2.0 - 1.0, raw_depth, 1.0);
	behind.xyz /= behind.w;
	vec3 behind_world = (INV_VIEW_MATRIX * vec4(behind.xyz, 1.0)).xyz;
	float depth = max(world_position.y - behind_world.y, 0.0);

	float murk = smoothstep(0.0, clarity_depth, depth);
	float edge_foam = (1.0 - smoothstep(0.0, foam_depth, depth)) * smoothstep(0.4, 0.7, h);
	float speed = length(flow);
	float flecks = smoothstep(0.68, 0.75, drifting(p, 0.13, vec2(5.0, 9.0))) * smoothstep(0.08, 0.4, speed) * fleck_amount;
	float foam = clamp(edge_foam * 0.8 + flecks, 0.0, 1.0);
	ALBEDO = mix(mix(shallow_color, deep_color, murk), foam_color, foam);
	ALPHA = clamp(mix(0.35, 0.85, murk) + foam * 0.5, 0.0, 1.0);
	ROUGHNESS = mix(0.17, 0.6, foam);
	SPECULAR = 0.35;
}
