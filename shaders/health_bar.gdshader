shader_type spatial;
render_mode blend_mix, depth_test_disabled, cull_disabled, unshaded;

uniform float health_ratio : hint_range(0.0, 1.0) = 1.0;
uniform vec4 healthy_color : source_color = vec4(0.2, 0.88, 0.35, 1.0);
uniform vec4 mid_color : source_color = vec4(0.95, 0.78, 0.2, 1.0);
uniform vec4 hurt_color : source_color = vec4(0.92, 0.22, 0.18, 1.0);
uniform vec4 bg_color : source_color = vec4(0.1, 0.12, 0.14, 0.85);
uniform vec4 border_color : source_color = vec4(0.02, 0.02, 0.02, 1.0);
uniform float border_width = 0.06;

void vertex() {
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
	MODELVIEW_NORMAL_MATRIX = mat3(MODELVIEW_MATRIX);
}

void fragment() {
	vec2 uv = UV;
	if (uv.x < border_width || uv.x > 1.0 - border_width || uv.y < border_width * 2.2 || uv.y > 1.0 - border_width * 2.2) {
		ALBEDO = border_color.rgb;
		ALPHA = border_color.a;
	} else {
		float bar_x = (uv.x - border_width) / (1.0 - 2.0 * border_width);
		vec4 bar_col;
		if (health_ratio > 0.5) {
			bar_col = mix(mid_color, healthy_color, (health_ratio - 0.5) * 2.0);
		} else {
			bar_col = mix(hurt_color, mid_color, health_ratio * 2.0);
		}
		if (bar_x <= health_ratio) {
			ALBEDO = bar_col.rgb;
			ALPHA = 1.0;
		} else {
			ALBEDO = bg_color.rgb;
			ALPHA = bg_color.a;
		}
	}
}
