shader_type spatial;
render_mode cull_disabled, specular_disabled;

uniform sampler2D albedo_texture : source_color, filter_nearest;
uniform vec4 base_color : source_color = vec4(1.0);
uniform vec4 tint_color : source_color = vec4(1.0, 1.0, 1.0, 0.0);
uniform float hit_flash : hint_range(0.0, 1.0) = 0.0;
uniform float dissolve : hint_range(0.0, 1.0) = 0.0;
varying vec3 local_position;

void vertex() {
	local_position = VERTEX;
}

void fragment() {
	vec3 cell = floor(local_position * 35.0);
	float noise = fract(sin(dot(cell, vec3(12.9898, 78.233, 37.719))) * 43758.5453);
	if (dissolve > 0.0 && noise < dissolve) {
		discard;
	}
	vec3 color = texture(albedo_texture, UV).rgb * base_color.rgb;
	if (tint_color.a > 0.0) {
		float lum = dot(color, vec3(0.299, 0.587, 0.114));
		color = mix(color, tint_color.rgb * (lum * 1.35 + 0.08), tint_color.a);
	}
	ALBEDO = mix(color, vec3(1.0, 0.5, 0.22), hit_flash * 0.7);
	float edge = dissolve > 0.0 ? 1.0 - smoothstep(dissolve, dissolve + 0.06, noise) : 0.0;
	EMISSION = vec3(0.55, 0.22, 0.06) * edge * 0.5;
	ROUGHNESS = 1.0;
}
