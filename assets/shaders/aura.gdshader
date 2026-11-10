shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never;
uniform vec4 energy_color : source_color = vec4(0.2, 0.7, 1.0, 1.0);
uniform float intensity = 1.0;
void vertex() {
 float wave = sin(VERTEX.y * 11.0 - TIME * 9.0 + VERTEX.x * 6.0);
 VERTEX += NORMAL * wave * 0.045 * intensity;
}
void fragment() {
 float rim = pow(1.0 - abs(dot(normalize(NORMAL), normalize(VIEW))), 2.0);
 float turbulence = 0.6 + 0.4 * sin(UV.x * 36.0 + sin(UV.y * 18.0 - TIME * 6.0) * 2.0 + TIME * 3.0);
 ALBEDO = energy_color.rgb;
 EMISSION = energy_color.rgb * (0.35 + turbulence * 0.45) * intensity;
 ALPHA = clamp(rim * turbulence * 0.35 * intensity, 0.0, 0.45);
}
