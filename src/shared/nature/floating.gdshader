shader_type spatial;

// The low-poly look of lowpoly.gdshader for things floating on water. Each
// MultiMesh instance bobs and turns a little, slowly and out of step with its
// neighbours. Colours are the material tint times the vertex and instance
// colours, picked in sRGB.

uniform vec4 albedo : source_color = vec4(1.0);
uniform float roughness : hint_range(0.0, 1.0) = 0.6;
uniform float bob_height = 0.006;
uniform float bob_speed = 0.9;
uniform float turn_angle = 0.05;

// Interpolated colours can overshoot below 0 at triangle edges (MSAA shades
// pixel centres outside the triangle), and pow() of a negative is NaN, which
// bloom spreads into a white blob. Hence the max().
vec3 srgb_to_linear(vec3 c) {
	c = max(c, vec3(0.0));
	return mix(c / 12.92, pow((c + 0.055) / 1.055, vec3(2.4)), step(0.04045, c));
}

void vertex() {
	vec3 origin = MODEL_MATRIX[3].xyz;
	float phase = dot(origin.xz, vec2(2.1, 1.3));
	float turn = sin(TIME * bob_speed * 0.45 + phase) * turn_angle;
	VERTEX.xz = mat2(vec2(cos(turn), sin(turn)), vec2(-sin(turn), cos(turn))) * VERTEX.xz;
	vec3 bob = vec3(0.0, sin(TIME * bob_speed + phase * 1.7) * bob_height, 0.0);
	VERTEX += (inverse(MODEL_MATRIX) * vec4(bob, 0.0)).xyz;
}

void fragment() {
	ALBEDO = albedo.rgb * srgb_to_linear(COLOR.rgb);
	ROUGHNESS = roughness;
	NORMAL = normalize(cross(dFdy(VERTEX), dFdx(VERTEX)));
}
