shader_type spatial;
render_mode blend_mix;

uniform vec4 tint_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float fresnel_power : hint_range(0.1, 10.0) = 3.0;
uniform float emission_power : hint_range(0.1, 10.0) = 3.0;
uniform float white_lerp : hint_range(0.0, 0.5) = 0.2;
uniform float scroll_speed = 0.2;
uniform sampler2D colors_texture : filter_nearest;

// New Pulse Configurations
uniform float pulse_speed : hint_range(0.0, 10.0) = 3.0;
uniform float pulse_min : hint_range(0.0, 1.0) = 0.4;
uniform float pulse_max : hint_range(1.0, 5.0) = 1.2;

void fragment() {
    // Generate a pulsing multiplier using a sine wave mapped between pulse_min and pulse_max
    float pulse = mix(pulse_min, pulse_max, (sin(TIME * pulse_speed) + 1.0) * 0.5);

    float f = clamp(pow(1.0 - dot(NORMAL, VIEW), fresnel_power), 0.0, 1.0);
    
    // Apply the pulse to the alpha, ensuring it doesn't exceed 1.0
    ALPHA = clamp(f * pulse, 0.0, 1.0);
    
    float t = clamp(f * white_lerp, 0.0, 1.0);
    float angle = atan(NORMAL.y, NORMAL.x);
    float u = (angle / (2.0 * 3.14159)) + 0.5;
    vec2 new_uv = vec2(mod(u + TIME * scroll_speed, 1.0), 0.0);
    
    vec3 tex_color = texture(colors_texture, new_uv).rgb;
    vec3 color = tex_color * tint_color.rgb;
    
    ALBEDO = mix(vec3(0.0), color, f);
    
    // Apply the pulse to the final emission power
    EMISSION = mix(color * f, vec3(1.0), t) * (emission_power * pulse);
}