shader_type spatial;
render_mode blend_mix, cull_disabled, depth_draw_never, shadows_disabled;

// A sheet of fog standing over the abyss: thick below and thinning to nothing at
// its top, drifting slowly, melting softly into the ground it passes through and
// fading out near the camera. Lit from above, so it darkens with the night.
// Vertex colour: red is how much shows along its length, alpha how thick the
// sheet is. UV.x is metres along it, UV.y 0 at the bottom and 1 at the top.

uniform sampler2D depth_texture : hint_depth_texture, filter_linear_mipmap, repeat_disable;
uniform vec3 mist : source_color = vec3(0.93, 0.95, 0.97);
uniform float drift = 0.012;
// How many metres a sheet takes to melt into the ground behind it.
uniform float soft_metres = 9.0;

varying vec3 world_position;

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float value_noise(vec2 p) {
	vec2 cell = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(cell), hash(cell + vec2(1.0, 0.0)), f.x), mix(hash(cell + vec2(0.0, 1.0)), hash(cell + vec2(1.0, 1.0)), f.x), f.y);
}

void fragment() {
	vec2 at = vec2(UV.x * 0.022 + TIME * drift, world_position.y * 0.035 - TIME * drift * 0.4);
	// Turned between layers, or the noise's square cells show as boxes.
	vec2 turned = mat2(vec2(0.8, 0.6), vec2(-0.6, 0.8)) * at * 2.3 + 13.0;
	vec2 again = mat2(vec2(0.28, 0.96), vec2(-0.96, 0.28)) * at * 5.1 + 29.0;
	float billows = value_noise(at + 0.4 * sin(turned.yx)) * 0.55 + value_noise(turned) * 0.3 + value_noise(again) * 0.15;
	// The top is ragged, not a ruled line.
	float top = smoothstep(0.0, 0.16, 1.0 - UV.y - (billows - 0.5) * 0.1);
	float depth = textureLod(depth_texture, SCREEN_UV, 0.0).r;
	vec4 behind = INV_PROJECTION_MATRIX * vec4(SCREEN_UV * 2.0 - 1.0, depth, 1.0);
	behind.xyz /= behind.w;
	float soft = clamp((VERTEX.z - behind.z) / soft_metres, 0.0, 1.0);
	float near = smoothstep(3.0, 30.0, length(VERTEX));
	float thick = clamp(COLOR.a * (0.72 + 0.56 * billows), 0.0, 1.0);
	ALBEDO = mist * (0.9 + 0.2 * billows);
	NORMAL = (VIEW_MATRIX * vec4(0.0, 1.0, 0.0, 0.0)).xyz;
	ROUGHNESS = 1.0;
	SPECULAR = 0.0;
	ALPHA = thick * top * soft * near * COLOR.r;
}
