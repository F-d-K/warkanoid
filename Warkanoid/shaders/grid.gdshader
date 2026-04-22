shader_type canvas_item;

uniform float time  : hint_range(0.0, 1000.0) = 0.0;
uniform float pulse : hint_range(0.0, 3.0)    = 0.0;

void fragment() {
	vec2 uv = UV;

	// Perspective depth: y=0 is top (far/horizon), y=1 is bottom (near/viewer)
	// Non-linear to get strong perspective convergence
	float t = 1.0 - uv.y;            // 0=near(bottom), 1=far(top)
	float z = 0.25 + t * t * 18.0;   // depth grows fast near horizon

	// World-space coordinates
	float wx = (uv.x - 0.5) * z;
	float wz = z * 0.4 + time * 1.8; // scroll toward viewer

	// Grid in world space
	float cell = 1.0;
	vec2 g = fract(vec2(wx, wz) / cell);

	// Line width in world space (thinner far away = narrower in screen space)
	float lw = 0.05;
	float hl = smoothstep(lw, 0.0, g.y) + smoothstep(1.0 - lw, 1.0, g.y);
	float vl = smoothstep(lw, 0.0, g.x) + smoothstep(1.0 - lw, 1.0, g.x);
	float on_line = clamp(hl + vl, 0.0, 1.0);

	// Fade to nothing at the horizon (top ~15%)
	float fade = clamp(uv.y * 5.0, 0.0, 1.0);

	// Line color: green-cyan, brighter on pulse
	vec3 line_col  = mix(vec3(0.06, 0.88, 0.55), vec3(0.25, 1.0, 0.72), pulse * 0.45);
	float bright   = 0.80 + pulse * 0.45;

	vec3 col = vec3(0.02, 0.03, 0.06); // deep dark background
	col = mix(col, line_col * bright, on_line * fade * 0.95);

	// Horizon glow
	float hglow = smoothstep(0.18, 0.0, uv.y);
	col += vec3(0.04, 0.55, 0.32) * hglow * (0.45 + pulse * 0.3);

	// Node intersections pulse
	vec2 g2    = fract(vec2(wx, wz) / cell) - 0.5;
	float node = smoothstep(0.18, 0.0, length(g2));
	float npls  = 0.5 + 0.5 * sin(time * 2.4 + wx * 3.1 + wz * 2.7);
	col += line_col * node * npls * fade * (0.35 + pulse * 0.25);

	// Vignette
	vec2  vc  = UV * 2.0 - 1.0;
	float vig = 1.0 - dot(vc * vec2(0.65, 1.0), vc * vec2(0.65, 1.0)) * 0.38;
	col *= clamp(vig, 0.0, 1.0);

	COLOR = vec4(col, 1.0);
}
