shader_type canvas_item;

uniform float scan_count  : hint_range(100.0, 600.0) = 300.0;
uniform float scan_dark   : hint_range(0.0, 0.6)     = 0.18;
uniform float vign_str    : hint_range(0.0, 1.5)     = 0.55;
uniform float time        : hint_range(0.0, 1000.0)  = 0.0;

void fragment() {
	// Horizontal scanlines: darken every other line
	float scan = mod(floor(UV.y * scan_count), 2.0) * scan_dark;

	// Very subtle rolling bar (CRT interference ghost)
	float bar_y = fract(UV.y - time * 0.045);
	float bar   = (1.0 - smoothstep(0.0, 0.010, bar_y)) * 0.032;

	// Vignette: dark corners, clear center
	vec2  c   = UV * 2.0 - 1.0;
	float vig = dot(c * vec2(0.78, 1.0), c * vec2(0.78, 1.0));
	float vig_dark = pow(clamp(vig, 0.0, 1.0), 1.1) * vign_str * 0.55;

	// Slight horizontal pixel brightness shimmer
	float shimmer = sin(UV.x * 1200.0 + time * 0.3) * 0.008;

	float alpha = clamp(scan + bar + vig_dark + shimmer, 0.0, 0.82);
	COLOR = vec4(0.0, 0.0, 0.0, alpha);
}
