shader_type canvas_item;

uniform float time          : hint_range(0.0, 1000.0) = 0.0;
uniform float pulse         : hint_range(0.0, 3.0)    = 0.0;
uniform float hue_offset    : hint_range(0.0, 1.0)    = 0.0;
uniform float speed_mult    : hint_range(0.1, 6.0)    = 1.0;
uniform float ripple_str    : hint_range(0.0, 3.0)    = 0.0;
uniform vec2  ripple_pos                               = vec2(0.5, 0.5);
uniform float intensity     : hint_range(0.3, 2.0)    = 1.0;

vec3 hsv2rgb(vec3 c) {
	vec4 K = vec4(1.0, 2.0/3.0, 1.0/3.0, 3.0);
	vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
	return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

void fragment() {
	vec2 uv = UV;
	float t = time * speed_mult * 0.6;

	// Ripple distortion
	float d = distance(uv, ripple_pos);
	float ripple = sin(d * 18.0 - t * 4.0) * ripple_str * 0.025 * exp(-d * 3.5);
	uv += normalize(uv - ripple_pos + vec2(0.001)) * ripple;

	// Multi-layer plasma
	float p1 = sin(uv.x * 4.1 + t * 1.1) * cos(uv.y * 3.7 - t * 0.9);
	float p2 = sin((uv.x + uv.y) * 5.3 + t * 0.7);
	float p3 = cos(length(uv - vec2(0.5 + sin(t*0.4)*0.3, 0.5 + cos(t*0.3)*0.3)) * 9.0 - t * 1.3);
	float p4 = sin(uv.x * 7.2 - t * 1.6) * sin(uv.y * 6.8 + t * 1.2);
	float p5 = cos(uv.x * 3.1 + uv.y * 4.4 + t * 0.8) * sin(uv.x * 2.2 - uv.y * 5.1 - t);
	float p6 = sin(length(uv - vec2(0.5)) * 12.0 - t * 2.0 + pulse * 3.14159);

	float plasma = (p1 + p2 + p3 + p4 + p5 + p6) / 6.0;
	plasma = plasma * 0.5 + 0.5;
	plasma = clamp(plasma + pulse * 0.18, 0.0, 1.0);

	// ── Warm beige / amber palette (inspired by splash mascot) ──────────────
	// Low plasma  → parchment cream  (hue≈0.07, sat≈0.08, val≈0.80)
	// Mid plasma  → warm peach/gold  (hue≈0.10, sat≈0.50, val≈0.65)
	// High plasma → deep amber       (hue≈0.15, sat≈0.82, val≈0.52)

	float warm_base = mix(0.060, 0.155, plasma);
	float hue       = warm_base + fract(hue_offset) * 0.065;

	float sat = mix(0.07, 0.84, pow(plasma, 1.6)) + pulse * 0.12;
	sat = clamp(sat, 0.0, 0.90);

	float val = mix(0.80, 0.48, plasma) * intensity + pulse * 0.13;
	val = clamp(val, 0.14, 1.0);

	vec3 col = hsv2rgb(vec3(hue, sat, val));
	COLOR = vec4(col, 1.0);
}
