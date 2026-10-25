shader_type spatial;

// Castle stonework: a world-space running-bond block pattern with mortar
// lines and per-block shade variation. Flat faces project onto the plane they
// face; set `cylindrical` for round towers so the blocks wrap around them.

uniform vec3 stone_color : source_color = vec3(0.8, 0.78, 0.73);
uniform vec3 mortar_color : source_color = vec3(0.58, 0.56, 0.52);
uniform vec2 block_size = vec2(1.1, 0.55);
uniform float mortar_width = 0.06;
uniform float variation : hint_range(0.0, 0.3) = 0.1;
uniform bool cylindrical = false;

varying vec3 world_position;
varying vec3 world_normal;
varying vec3 local_position;

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_normal = normalize(MODEL_NORMAL_MATRIX * NORMAL);
	local_position = VERTEX;
}

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
	vec3 n = abs(world_normal);
	vec2 plane;
	if (n.y > max(n.x, n.z)) {
		plane = world_position.xz;
	} else if (cylindrical) {
		plane = vec2(atan(local_position.z, local_position.x) * length(local_position.xz), world_position.y);
	} else if (n.x > n.z) {
		plane = world_position.zy;
	} else {
		plane = world_position.xy;
	}
	vec2 cell = plane / block_size;
	cell.x += mod(floor(cell.y), 2.0) * 0.5;
	vec2 inside = fract(cell) * block_size;
	vec2 to_edge = min(inside, block_size - inside);
	float edge = min(to_edge.x, to_edge.y);
	float blur = max(fwidth(edge), 1e-4);
	float mortar = 1.0 - smoothstep(mortar_width * 0.5 - blur, mortar_width * 0.5 + blur, edge);
	// Far away the pattern would shimmer, so it fades into an even tone.
	float detail = 1.0 - smoothstep(0.25, 0.6, max(fwidth(cell.x), fwidth(cell.y)));
	float shade = 1.0 + (hash(floor(cell)) - 0.5) * 2.0 * variation * detail;
	vec3 stone = stone_color * shade;
	ALBEDO = mix(stone, mix(stone, mortar_color, 0.5), mix(0.0, mortar, detail));
	ROUGHNESS = 0.92;
}
