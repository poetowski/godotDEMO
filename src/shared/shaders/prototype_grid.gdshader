shader_type spatial;

// Prototype grid for greybox geometry. Projects a world-space grid onto the
// axis plane each surface faces, so blocks of any size read in metres:
// thin lines every `minor_size`, bold lines every `major_size`.

uniform vec3 base_color : source_color = vec3(0.45, 0.47, 0.5);
uniform vec3 line_color : source_color = vec3(0.24, 0.25, 0.27);
uniform vec3 major_line_color : source_color = vec3(0.12, 0.13, 0.14);
uniform float minor_size = 1.0;
uniform float major_size = 10.0;
uniform float minor_width_px = 1.0;
uniform float major_width_px = 2.0;
uniform float checker_strength : hint_range(0.0, 0.2) = 0.04;
uniform float surface_roughness : hint_range(0.0, 1.0) = 0.85;

varying vec3 world_position;
varying vec3 world_normal;

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_normal = normalize(MODEL_NORMAL_MATRIX * NORMAL);
}

// 1.0 on a grid line, 0.0 off it. Lines keep a constant width in pixels and
// fade out before their cells get small enough to alias.
float grid_lines(vec2 position, float cell_size, float width_px) {
	vec2 coord = position / cell_size;
	vec2 per_pixel = max(fwidth(coord), vec2(1e-5));
	vec2 distance_px = abs(fract(coord - 0.5) - 0.5) / per_pixel;
	float line = 1.0 - clamp(min(distance_px.x, distance_px.y) - width_px * 0.5 + 0.5, 0.0, 1.0);
	float fade = 1.0 - smoothstep(0.1, 0.3, max(per_pixel.x, per_pixel.y));
	return line * fade;
}

void fragment() {
	vec3 n = abs(world_normal);
	vec2 plane = n.y >= max(n.x, n.z) ? world_position.xz
		: (n.x >= n.z ? world_position.zy : world_position.xy);
	vec2 cell = floor(plane / minor_size);
	float checker = mod(cell.x + cell.y, 2.0) * 2.0 - 1.0;
	vec3 color = base_color * (1.0 + checker * checker_strength);
	color = mix(color, line_color, grid_lines(plane, minor_size, minor_width_px));
	color = mix(color, major_line_color, grid_lines(plane, major_size, major_width_px));
	ALBEDO = color;
	ROUGHNESS = surface_roughness;
}
