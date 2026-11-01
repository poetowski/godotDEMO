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
// Region borders: wider, and never thinner than a pixel or two at any distance.
uniform vec3 region_line_color : source_color = vec3(1.0, 0.72, 0.28);
uniform float region_line_width = 0.5;
// Off hides both kinds of line, from the G key (SectorGrid.set_marks_shown).
uniform bool show_lines = true;
uniform float region_sectors = 20.0;
// World x and z of A1's south-west corner; the grid runs east and north from it.
uniform vec2 grid_origin = vec2(0.0, 0.0);
uniform float sector_size = 10.0;
uniform vec2 grid_sectors = vec2(20.0, 20.0);

global uniform sampler2D terrain_paint_first : filter_linear, repeat_disable;
global uniform sampler2D terrain_paint_second : filter_linear, repeat_disable;
global uniform vec2 terrain_paint_size;
// World x and north of the paint textures' first texel.
uniform vec2 paint_origin = vec2(0.0, 0.0);

// Placeholder: every painted surface's colours.
const vec3 DIRT = vec3(0.45, 0.33, 0.21);
const vec3 MUD = vec3(0.33, 0.25, 0.17);
const vec3 GRAVEL = vec3(0.52, 0.50, 0.45);
const vec3 SAND = vec3(0.70, 0.62, 0.45);
const vec3 DRY_GRASS = vec3(0.68, 0.62, 0.33);
const vec3 LUSH_GRASS = vec3(0.20, 0.42, 0.14);
const vec3 COBBLE = vec3(0.46, 0.45, 0.43);
const vec3 FLAGSTONE = vec3(0.60, 0.57, 0.50);
const vec3 JOINT = vec3(0.17, 0.15, 0.13);
const vec3 BEDDING = vec3(0.34, 0.28, 0.20);

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
// lies (0 at the joint), y a number belonging to that stone, `middle` its centre.
vec2 stones(vec2 p, out vec2 middle) {
	vec2 cell = floor(p);
	float nearest = 8.0;
	float second = 8.0;
	float id = 0.0;
	middle = p;
	for (int y = -1; y <= 1; y++) {
		for (int x = -1; x <= 1; x++) {
			vec2 c = cell + vec2(float(x), float(y));
			vec2 centre = c + 0.2 + 0.6 * vec2(hash(c), hash(c + 17.3));
			float d = length(p - centre);
			if (d < nearest) {
				second = nearest;
				nearest = d;
				id = hash(c + 5.1);
				middle = centre;
			} else if (d < second) {
				second = d;
			}
		}
	}
	return vec2(second - nearest, id);
}

// Running-bond slabs, as stones() answers.
vec2 slabs(vec2 p, out vec2 middle) {
	vec2 size = vec2(1.15, 0.75);
	float row = floor(p.y / size.y);
	float shift = mod(row, 2.0) * 0.5;
	vec2 slab = vec2(floor(p.x / size.x + shift), row);
	vec2 inside = vec2(fract(p.x / size.x + shift) * size.x, fract(p.y / size.y) * size.y);
	vec2 to_edge = min(inside, size - inside);
	middle = vec2((slab.x + 0.5 - shift) * size.x, (row + 0.5) * size.y);
	return vec2(min(to_edge.x, to_edge.y), hash(slab + 3.7));
}

// Where a world x and z lies in the paint textures.
vec2 paint_uv_at(vec2 world) {
	return (vec2(world.x, -world.y) - paint_origin + 0.5) / terrain_paint_size;
}

// How much of a pattern is left at the edge of a stroke, torn up by grit that fades
// at a distance, so strokes end in crumbs instead of the 1 m grid's shapes.
float torn(float amount, float grit, float fine) {
	return smoothstep(0.14, 0.58, amount + (grit - 0.5) * 0.42 * fine);
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

	// Strokes wander up to about a metre from where they were laid, so their edges
	// aren't the blobs of a 1 m grid, and four samples round off its corners.
	vec2 wander = (vec2(value_noise(p * 0.37 + 3.0), value_noise(p * 0.37 + 53.0)) - 0.5) * 1.3;
	wander += (vec2(value_noise(p * 1.3), value_noise(p * 1.3 + 41.0)) - 0.5) * 0.9;
	wander += (vec2(value_noise(p * 4.1 + 9.0), value_noise(p * 4.1 + 77.0)) - 0.5) * 0.32;
	vec2 paint_uv = paint_uv_at(p + wander);
	vec2 texel = 0.5 / terrain_paint_size;
	vec4 first = 0.25 * (texture(terrain_paint_first, paint_uv + texel) + texture(terrain_paint_first, paint_uv - texel)
		+ texture(terrain_paint_first, paint_uv + vec2(texel.x, -texel.y)) + texture(terrain_paint_first, paint_uv + vec2(-texel.x, texel.y)));
	vec4 second = 0.25 * (texture(terrain_paint_second, paint_uv + texel) + texture(terrain_paint_second, paint_uv - texel)
		+ texture(terrain_paint_second, paint_uv + vec2(texel.x, -texel.y)) + texture(terrain_paint_second, paint_uv + vec2(-texel.x, texel.y)));
	vec2 inside_world = step(vec2(0.0), paint_uv) * step(paint_uv, vec2(1.0));
	first *= inside_world.x * inside_world.y;
	second *= inside_world.x * inside_world.y;
	float pixel = length(fwidth(p));
	float fine = detail(0.3, pixel);
	float grit = value_noise(p * 6.3) * 0.6 + value_noise(p * 17.0) * 0.4;
	float painted = 0.0;

	// Feet wear the grass thin and yellow for a couple of metres around bare ground.
	vec2 far = 2.4 * 2.0 * texel;
	vec2 far_uv = paint_uv_at(p);
	vec4 near_a = texture(terrain_paint_first, far_uv + far) + texture(terrain_paint_first, far_uv - far);
	vec4 near_b = texture(terrain_paint_second, far_uv + vec2(far.x, -far.y)) + texture(terrain_paint_second, far_uv + vec2(-far.x, far.y));
	float worn = near_a.r + near_a.g + near_a.b + near_a.a + near_b.b + near_b.a;
	worn = smoothstep(0.05, 0.7, worn) * inside_world.x * inside_world.y * (0.35 + 0.65 * value_noise(p * 2.3));
	ground = mix(ground, ground * vec3(1.12, 0.94, 0.62) * (0.78 + 0.3 * grit), worn * 0.7);

	if (first.r > 0.004) {
		float share = torn(first.r, grit, fine);
		vec2 where;
		vec2 pebble = stones(p * 17.0, where);
		float speck = smoothstep(0.9, 0.96, pebble.y) * smoothstep(0.02, 0.14, pebble.x) * detail(0.1, pixel);
		float damp = smoothstep(0.42, 0.7, value_noise(p * 0.73 + 11.0));
		vec3 dirt = srgb_to_linear(DIRT) * (0.74 + 0.3 * patches + 0.34 * grit * detail(0.2, pixel)) * (1.0 - 0.3 * damp);
		dirt = mix(dirt, srgb_to_linear(GRAVEL) * (0.45 + 0.4 * pebble.y), speck);
		paint_over(ground, roughness, dirt, share, 0.98 - 0.2 * damp);
		painted = max(painted, share);
	}
	if (first.g > 0.004) {
		float share = torn(first.g, grit, fine);
		float wet = smoothstep(0.5, 0.72, value_noise(p * 1.1 + 31.0));
		vec3 mud = srgb_to_linear(MUD) * (0.68 + 0.5 * value_noise(p * 1.9) + 0.18 * grit * fine) * (1.0 - 0.35 * wet);
		paint_over(ground, roughness, mud, share, mix(0.62, 0.16, wet));
		painted = max(painted, share);
	}
	if (first.b > 0.004) {
		vec2 where;
		vec2 stone = stones(p * 8.5, where);
		float share = torn(first.b, stone.y, fine);
		vec3 tone = srgb_to_linear(GRAVEL) * mix(1.0, 0.55 + 0.85 * stone.y, fine) * mix(vec3(1.0), vec3(1.06, 0.98, 0.88), value_noise(p * 3.1));
		vec3 gravel = mix(tone, srgb_to_linear(BEDDING) * 0.7, smoothstep(0.2, 0.0, stone.x) * fine);
		paint_over(ground, roughness, gravel, share, 0.92);
		painted = max(painted, share);
	}
	if (first.a > 0.004) {
		float share = torn(first.a, grit, fine);
		float ripple = sin((p.x * 0.7 + p.y + value_noise(p * 0.6) * 5.0) * 5.0) * detail(0.4, pixel);
		vec2 where;
		vec2 pebble = stones(p * 15.0, where);
		float speck = smoothstep(0.86, 0.94, pebble.y) * smoothstep(0.02, 0.14, pebble.x) * detail(0.1, pixel);
		vec3 sand = srgb_to_linear(SAND) * (0.8 + 0.22 * patches + 0.025 * ripple + 0.2 * grit * detail(0.12, pixel));
		sand = mix(sand, srgb_to_linear(GRAVEL) * (0.55 + 0.5 * pebble.y), speck);
		paint_over(ground, roughness, sand, share, 0.96);
		painted = max(painted, share);
	}
	if (second.r > 0.004) {
		float share = torn(second.r, grit, fine);
		float strands = value_noise(vec2(p.x * 9.0 + p.y * 3.0, p.y * 1.6 - p.x * 0.8));
		vec3 straw = srgb_to_linear(DRY_GRASS) * (0.62 + 0.35 * patches + 0.34 * strands * detail(0.2, pixel));
		paint_over(ground, roughness, straw, share, 0.95);
		painted = max(painted, share * 0.5);
	}
	if (second.g > 0.004) {
		float share = torn(second.g, grit, fine);
		float strands = value_noise(vec2(p.x * 8.0 - p.y * 2.0, p.y * 1.4 + p.x * 0.6));
		vec3 lush = srgb_to_linear(LUSH_GRASS) * (0.66 + 0.4 * patches + 0.34 * strands * detail(0.2, pixel));
		paint_over(ground, roughness, lush, share, 0.95);
	}
	if (second.b > 0.004) {
		// Whole stones or none: each asks the paint at its own middle, and they lie in
		// packed earth that shows where the road gives out.
		vec2 middle;
		vec2 stone = stones(p * 4.6, middle);
		float reach = texture(terrain_paint_second, paint_uv_at(middle / 4.6)).b;
		float laid = mix(smoothstep(0.3, 0.5, second.b), step(0.36 + stone.y * 0.34, reach), fine);
		paint_over(ground, roughness, srgb_to_linear(BEDDING) * (0.78 + 0.4 * grit), torn(second.b, grit, fine), 0.98);
		vec3 face = srgb_to_linear(COBBLE) * mix(1.0, 0.6 + 0.72 * stone.y, fine) * mix(vec3(1.0), vec3(1.07, 1.0, 0.9), value_noise(middle * 1.7));
		face *= mix(1.0, 0.76 + 0.42 * smoothstep(0.0, 0.42, stone.x), fine);
		vec3 cobble = mix(face, srgb_to_linear(JOINT), smoothstep(0.13, 0.03, stone.x) * fine);
		paint_over(ground, roughness, cobble, laid * mix(1.0, smoothstep(0.015, 0.06, stone.x), fine), 0.74);
		painted = max(painted, torn(second.b, grit, fine));
	}
	if (second.a > 0.004) {
		vec2 middle;
		vec2 skew = (vec2(value_noise(p * 3.3), value_noise(p * 3.3 + 29.0)) - 0.5) * 0.13;
		vec2 stone = slabs(p + skew, middle);
		float reach = texture(terrain_paint_second, paint_uv_at(middle)).a;
		float laid = mix(smoothstep(0.3, 0.5, second.a), step(0.34 + stone.y * 0.3, reach), fine);
		paint_over(ground, roughness, srgb_to_linear(BEDDING) * (0.78 + 0.4 * grit), torn(second.a, grit, fine), 0.98);
		vec3 face = srgb_to_linear(FLAGSTONE) * mix(1.0, 0.72 + 0.46 * stone.y + 0.2 * grit, fine);
		face *= mix(1.0, 0.8 + 0.3 * smoothstep(0.0, 0.12, stone.x), fine);
		paint_over(ground, roughness, face, laid * mix(1.0, smoothstep(0.012, 0.04, stone.x), fine), 0.8);
		painted = max(painted, torn(second.a, grit, fine));
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
	float line = max(on_line.x, on_line.y) * inside_x * inside_y * grassiness * (1.0 - painted) * float(show_lines);

	vec2 to_region = abs(grid - sector_size * region_sectors * round(grid / (sector_size * region_sectors)));
	vec2 region_half = max(vec2(region_line_width * 0.5), per_pixel);
	vec2 on_region = clamp((region_half + per_pixel * 0.5 - to_region) / per_pixel, 0.0, 1.0);
	float region_line = max(on_region.x, on_region.y) * inside_x * inside_y * float(show_lines);

	ALBEDO = mix(mix(ground, line_color * 0.5, line), region_line_color * 0.5, region_line);
	EMISSION = mix(line_color * line_energy * line, region_line_color * line_energy, region_line);
	ROUGHNESS = roughness;
}
