shader_type spatial;

// Grass ground with the sector grid painted on it as glowing lines. The grass
// varies in soft world-space patches. Designed sectors paint their own ground
// through vertex colours: alpha is how much grass shows, and the colour (in
// sRGB) what shows instead, such as mud under a stream; the lines fade with
// the grass. Lines have a fixed width in metres, cover only the grid's area,
// and thin out with distance instead of shimmering. Over all that lies what was
// painted by hand (TerrainPaint): two textures of shares, one texel a metre.

uniform vec3 grass_light : source_color = vec3(0.44, 0.62, 0.26);
uniform vec3 grass_dark : source_color = vec3(0.27, 0.46, 0.18);
uniform vec3 line_color : source_color = vec3(0.55, 0.9, 1.0);
uniform float line_energy = 1.8;
uniform float line_width = 0.14;
// World x and z of A1's south-west corner; the grid runs east and north from it.
uniform vec2 grid_origin = vec2(0.0, 0.0);
uniform float sector_size = 10.0;
uniform vec2 grid_sectors = vec2(20.0, 20.0);

global uniform sampler2D terrain_paint_first : filter_linear, repeat_disable;
global uniform sampler2D terrain_paint_second : filter_linear, repeat_disable;
global uniform vec2 terrain_paint_size;

// Placeholder: every painted surface's colours.
const vec3 DIRT = vec3(0.45, 0.33, 0.21);
const vec3 MUD = vec3(0.33, 0.25, 0.17);
const vec3 GRAVEL = vec3(0.52, 0.50, 0.45);
const vec3 SAND = vec3(0.80, 0.72, 0.52);
const vec3 DRY_GRASS = vec3(0.68, 0.62, 0.33);
const vec3 LUSH_GRASS = vec3(0.20, 0.42, 0.14);
const vec3 COBBLE = vec3(0.46, 0.45, 0.43);
const vec3 FLAGSTONE = vec3(0.60, 0.57, 0.50);
const vec3 JOINT = vec3(0.17, 0.15, 0.13);

varying vec3 world_position;

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

// Interpolated colours can overshoot below 0 at triangle edges (MSAA shades
// pixel centres outside the triangle), and pow() of a negative is NaN, which
// bloom spreads into a white blob. Hence the max().
vec3 srgb_to_linear(vec3 c) {
	c = max(c, vec3(0.0));
	return mix(c / 12.92, pow((c + 0.055) / 1.055, vec3(2.4)), step(0.04045, c));
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

// Nearest stone in a field of rounded stones: x is how far inside it the point
// lies (0 at the joint), y a number belonging to that stone.
vec2 stones(vec2 p) {
	vec2 cell = floor(p);
	float nearest = 8.0;
	float second = 8.0;
	float id = 0.0;
	for (int y = -1; y <= 1; y++) {
		for (int x = -1; x <= 1; x++) {
			vec2 c = cell + vec2(float(x), float(y));
			vec2 centre = c + 0.2 + 0.6 * vec2(hash(c), hash(c + 17.3));
			float d = length(p - centre);
			if (d < nearest) {
				second = nearest;
				nearest = d;
				id = hash(c + 5.1);
			} else if (d < second) {
				second = d;
			}
		}
	}
	return vec2(second - nearest, id);
}

// Running-bond slabs, as stones() answers.
vec2 slabs(vec2 p) {
	vec2 size = vec2(1.15, 0.75);
	float row = floor(p.y / size.y);
	float shift = mod(row, 2.0) * 0.5;
	vec2 slab = vec2(floor(p.x / size.x + shift), row);
	vec2 inside = vec2(fract(p.x / size.x + shift) * size.x, fract(p.y / size.y) * size.y);
	vec2 to_edge = min(inside, size - inside);
	return vec2(min(to_edge.x, to_edge.y), hash(slab + 3.7));
}

// Fades a pattern's fine marks out once they're smaller than a pixel.
float detail(float metres, float per_pixel) {
	return 1.0 - smoothstep(metres * 0.25, metres, per_pixel);
}

void paint_over(inout vec3 ground, inout float roughness, vec3 surface, float share, float rough) {
	ground = mix(ground, surface, share);
	roughness = mix(roughness, rough, share);
}

void fragment() {
	vec2 p = world_position.xz;
	float patches = value_noise(p * 0.045) * 0.65 + value_noise(p * 0.21) * 0.35;
	vec3 grass = mix(grass_dark, grass_light, patches);
	grass *= 0.95 + 0.1 * value_noise(p * 2.7);
	vec3 earth = srgb_to_linear(COLOR.rgb) * (0.88 + 0.24 * value_noise(p * 3.3));
	float grassiness = clamp(COLOR.a, 0.0, 1.0);
	vec3 ground = mix(earth, grass, grassiness);
	float roughness = 0.95;

	// A little wander, so painted edges aren't the round blobs of a 1 m grid.
	vec2 wander = vec2(value_noise(p * 1.3), value_noise(p * 1.3 + 41.0)) - 0.5;
	wander += (vec2(value_noise(p * 4.1 + 9.0), value_noise(p * 4.1 + 77.0)) - 0.5) * 0.35;
	vec2 paint_uv = (vec2(p.x, -p.y) + wander * 0.9 + 0.5) / terrain_paint_size;
	vec4 first = texture(terrain_paint_first, paint_uv);
	vec4 second = texture(terrain_paint_second, paint_uv);
	vec2 inside_world = step(vec2(0.0), paint_uv) * step(paint_uv, vec2(1.0));
	first *= inside_world.x * inside_world.y;
	second *= inside_world.x * inside_world.y;
	float pixel = length(fwidth(p));
	float painted = 0.0;
	if (first.r > 0.004) {
		float share = smoothstep(0.08, 0.72, first.r);
		vec3 dirt = srgb_to_linear(DIRT) * (0.8 + 0.28 * patches + 0.3 * value_noise(p * 5.3) * detail(0.2, pixel));
		paint_over(ground, roughness, dirt, share, 0.98);
		painted = max(painted, share);
	}
	if (first.g > 0.004) {
		float share = smoothstep(0.08, 0.72, first.g);
		vec3 mud = srgb_to_linear(MUD) * (0.75 + 0.6 * value_noise(p * 1.9));
		paint_over(ground, roughness, mud, share, 0.42);
		painted = max(painted, share);
	}
	if (first.b > 0.004) {
		float fine = detail(0.25, pixel);
		vec2 stone = stones(p * 7.0);
		float share = smoothstep(0.08, 0.72, first.b + (stone.y - 0.5) * 0.3 * fine);
		vec3 tone = srgb_to_linear(GRAVEL) * mix(1.0, 0.62 + 0.75 * stone.y, fine);
		paint_over(ground, roughness, mix(tone, tone * 0.55, smoothstep(0.18, 0.0, stone.x) * fine), share, 0.92);
		painted = max(painted, share);
	}
	if (first.a > 0.004) {
		float share = smoothstep(0.08, 0.72, first.a);
		float ripple = sin((p.x * 0.7 + p.y + value_noise(p * 0.6) * 5.0) * 7.0) * detail(0.4, pixel);
		vec3 sand = srgb_to_linear(SAND) * (0.92 + 0.05 * ripple + 0.14 * value_noise(p * 8.7) * detail(0.12, pixel));
		paint_over(ground, roughness, sand, share, 0.96);
		painted = max(painted, share);
	}
	if (second.r > 0.004) {
		float share = smoothstep(0.08, 0.72, second.r);
		vec3 straw = srgb_to_linear(DRY_GRASS) * (0.72 + 0.35 * patches + 0.18 * value_noise(p * 2.7));
		paint_over(ground, roughness, straw, share, 0.95);
		painted = max(painted, share * 0.5);
	}
	if (second.g > 0.004) {
		float share = smoothstep(0.08, 0.72, second.g);
		vec3 lush = srgb_to_linear(LUSH_GRASS) * (0.72 + 0.4 * patches + 0.2 * value_noise(p * 2.7));
		paint_over(ground, roughness, lush, share, 0.95);
	}
	if (second.b > 0.004) {
		float fine = detail(0.3, pixel);
		vec2 stone = stones(p * 3.1);
		float share = smoothstep(0.32, 0.5, second.b + (stone.y - 0.5) * 0.25 * fine);
		vec3 face = srgb_to_linear(COBBLE) * mix(1.0, 0.66 + 0.62 * stone.y, fine);
		vec3 cobble = mix(face, srgb_to_linear(JOINT), smoothstep(0.2, 0.05, stone.x) * fine);
		paint_over(ground, roughness, cobble, share, 0.82);
		painted = max(painted, share);
	}
	if (second.a > 0.004) {
		float fine = detail(0.3, pixel);
		vec2 stone = slabs(p);
		float share = smoothstep(0.32, 0.5, second.a + (stone.y - 0.5) * 0.25 * fine);
		vec3 face = srgb_to_linear(FLAGSTONE) * mix(1.0, 0.76 + 0.42 * stone.y + 0.14 * value_noise(p * 6.1), fine);
		vec3 flag = mix(face, srgb_to_linear(JOINT), smoothstep(0.045, 0.012, stone.x) * fine);
		paint_over(ground, roughness, flag, share, 0.86);
		painted = max(painted, share);
	}

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
	float line = max(on_line.x, on_line.y) * inside_x * inside_y * grassiness * (1.0 - painted);

	ALBEDO = mix(ground, line_color * 0.5, line);
	EMISSION = line_color * line_energy * line;
	ROUGHNESS = roughness;
}
