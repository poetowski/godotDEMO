shader_type spatial;

// Flat-shaded low-poly surface: one normal per triangle. The colour is the
// material tint times the vertex or MultiMesh instance colour, which callers
// pick in sRGB like any other colour.

uniform vec4 albedo : source_color = vec4(1.0);
uniform float roughness : hint_range(0.0, 1.0) = 0.9;
uniform bool flat_shading = true;

// Interpolated colours can overshoot below 0 at triangle edges (MSAA shades
// pixel centres outside the triangle), and pow() of a negative is NaN, which
// bloom spreads into a white blob. Hence the max().
vec3 srgb_to_linear(vec3 c) {
	c = max(c, vec3(0.0));
	return mix(c / 12.92, pow((c + 0.055) / 1.055, vec3(2.4)), step(0.04045, c));
}

void fragment() {
	ALBEDO = albedo.rgb * srgb_to_linear(COLOR.rgb);
	ROUGHNESS = roughness;
	if (flat_shading) {
		NORMAL = normalize(cross(dFdy(VERTEX), dFdx(VERTEX)));
	}
}
