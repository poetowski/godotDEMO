shader_type spatial;

// A katana blade wreathed in fire: dark tempered steel at the spine, a
// glowing edge, and bands of flame light that flicker up the blade. UV.y runs
// from 0 at the guard to 1 at the tip; UV.x from 0 at the spine to 1 at the
// edge.

uniform vec3 steel : source_color = vec3(0.16, 0.13, 0.12);
uniform vec3 ember : source_color = vec3(1.0, 0.36, 0.08);
uniform vec3 core : source_color = vec3(1.0, 0.8, 0.35);
uniform float glow = 5.0;
uniform float flicker_speed = 2.2;

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
	float edge = smoothstep(0.35, 1.0, UV.x);
	float flames = value_noise(vec2(UV.x * 3.0, UV.y * 9.0 - TIME * flicker_speed));
	flames = flames * 0.7 + value_noise(vec2(UV.x * 7.0 + 4.0, UV.y * 21.0 - TIME * flicker_speed * 1.7)) * 0.3;
	float heat = clamp(edge * 0.8 + flames * 0.55 - 0.15, 0.0, 1.0);
	ALBEDO = mix(steel, ember * 0.4, heat);
	METALLIC = 0.6;
	ROUGHNESS = 0.3;
	EMISSION = mix(ember, core, heat * heat) * heat * glow;
}
