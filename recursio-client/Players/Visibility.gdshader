shader_type spatial;
render_mode unshaded;

uniform sampler2D visibility_mask;
uniform vec4 color: hint_color = vec4(1.0, 0.0, 0.0, 1.0);
uniform float visibility_threshold = 0.05;
uniform float camera_size = 70;
uniform bool always_draw = false;

varying vec3 world_vertex;

void vertex() {
	world_vertex = (WORLD_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 uv = world_vertex.xz;
	uv += vec2(camera_size / 2.0, camera_size / 2.0);
	uv /= camera_size;
	uv.y = 1.0 - uv.y;
	
	ALPHA_SCISSOR = 0.5;
	
	ALPHA = float(length(texture(visibility_mask, uv).rgb) > visibility_threshold || always_draw);
	ALBEDO = color.rgb;
}