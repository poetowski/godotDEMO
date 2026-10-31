shader_type spatial;
render_mode cull_disabled;

// Assets scattered in masses (PropLibrary.mass_mesh): the colour of the model's
// material times each copy's tint, the taller parts swaying gently in the wind,
// and things on water bobbing. Each copy keeps its own phase, so they don't move
// in step.

uniform vec3 albedo : source_color = vec3(1.0);
uniform float roughness = 0.9;
// Metres aside at one metre above the foot.
uniform float sway = 0.0;
// Metres up and down.
uniform float bob = 0.0;

varying vec3 tint;

void vertex() {
	float phase = MODEL_MATRIX[3].x * 0.71 + MODEL_MATRIX[3].z * 0.93;
	float up = max(VERTEX.y, 0.0);
	VERTEX.xz += sway * up * up * vec2(sin(TIME * 0.9 + phase), cos(TIME * 0.7 + phase * 1.3));
	VERTEX.y += bob * sin(TIME * 0.8 + phase);
	// Interpolated colours can dip below 0 at triangle edges.
	tint = clamp(COLOR.rgb, vec3(0.0), vec3(2.0));
}

void fragment() {
	ALBEDO = albedo * tint;
	ROUGHNESS = roughness;
	SPECULAR = 0.3;
}
