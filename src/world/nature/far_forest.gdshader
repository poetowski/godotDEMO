shader_type spatial;
render_mode cull_back;

// Stand-in trees for the distant forest, drawn as MultiMesh copies. Each copy
// dissolves (dithered) where the real trees take over: within `hide_within`
// metres of the camera it's gone, by `hide_within + fade` it's whole. Flat
// shaded, coloured by vertex colour (sRGB) like the rest of the low-poly
// world.

uniform float hide_within = 300.0;
uniform float fade = 70.0;

varying float shown;

vec3 srgb_to_linear(vec3 c) {
	c = max(c, vec3(0.0));
	return mix(c / 12.92, pow((c + 0.055) / 1.055, vec3(2.4)), step(0.04045, c));
}

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void vertex() {
	// For MultiMesh copies the model matrix includes the copy's own place.
	vec3 origin = MODEL_MATRIX[3].xyz;
	shown = smoothstep(hide_within, hide_within + fade, distance(origin.xz, CAMERA_POSITION_WORLD.xz));
	if (shown <= 0.0) {
		// Gone: fold the copy to a point, so nothing is drawn.
		VERTEX = vec3(0.0);
	}
}

void fragment() {
	if (hash(FRAGCOORD.xy) > shown) {
		discard;
	}
	ALBEDO = srgb_to_linear(COLOR.rgb);
	ROUGHNESS = 0.95;
	NORMAL = normalize(cross(dFdy(VERTEX), dFdx(VERTEX)));
}
