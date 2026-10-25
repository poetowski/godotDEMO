shader_type spatial;

// Flat grass ground with the sector grid painted on it as glowing lines.
// The grass varies in soft world-space patches. Lines have a fixed width in
// metres, cover only the grid's area, and thin out with distance instead of
// shimmering.

uniform vec3 grass_light : source_color = vec3(0.44, 0.62, 0.26);
uniform vec3 grass_dark : source_color = vec3(0.27, 0.46, 0.18);
uniform vec3 line_color : source_color = vec3(0.55, 0.9, 1.0);
uniform float line_energy = 1.8;
uniform float line_width = 0.14;
// World x and z of A1's south-west corner; the grid runs east and north from it.
uniform vec2 grid_origin = vec2(0.0, 0.0);
uniform float sector_size = 10.0;
uniform vec2 grid_sectors = vec2(20.0, 20.0);

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
	float a = hash(cell);
	float b = hash(cell + vec2(1.0, 0.0));
	float c = hash(cell + vec2(0.0, 1.0));
	float d = hash(cell + vec2(1.0, 1.0));
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

void fragment() {
	vec2 p = world_position.xz;
	float patches = value_noise(p * 0.045) * 0.65 + value_noise(p * 0.21) * 0.35;
	vec3 grass = mix(grass_dark, grass_light, patches);
	grass *= 0.95 + 0.1 * value_noise(p * 2.7);

	// Metres east and north of A1's corner.
	vec2 grid = vec2(p.x - grid_origin.x, grid_origin.y - p.y);
	vec2 extent = grid_sectors * sector_size;
	vec2 to_line = abs(grid - sector_size * round(grid / sector_size));
	vec2 per_pixel = max(fwidth(grid), vec2(1e-4));
	vec2 half_width = vec2(line_width * 0.5);
	vec2 on_line = clamp((half_width + per_pixel * 0.5 - to_line) / per_pixel, 0.0, 1.0);
	on_line *= clamp(line_width / per_pixel, 0.0, 1.0);
	float inside_x = step(-line_width, grid.x) * step(grid.x, extent.x + line_width);
	float inside_y = step(-line_width, grid.y) * step(grid.y, extent.y + line_width);
	float line = max(on_line.x, on_line.y) * inside_x * inside_y;

	ALBEDO = mix(grass, line_color * 0.5, line);
	EMISSION = line_color * line_energy * line;
	ROUGHNESS = 0.95;
}
