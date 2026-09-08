shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx, unshaded;

// Base Visuals
uniform vec4 albedo : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform sampler2D texture_albedo : source_color, filter_linear_mipmap, repeat_enable;

// Outline controls
uniform vec4 outline_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float outline_size : hint_range(0.0, 5.0, 0.1) = 1.5;

// Subway Surfers Globals
global uniform vec2 global_curve_intensity;
global uniform float global_curve_start;

// Tracking screen position for the outline calculation
varying vec4 v_screen_pos;

void vertex() {
    // 1. Core Billboarding
    MODELVIEW_MATRIX = VIEW_MATRIX * mat4(
            MAIN_CAM_INV_VIEW_MATRIX[0],
            MAIN_CAM_INV_VIEW_MATRIX[1],
            MAIN_CAM_INV_VIEW_MATRIX[2],
            MODEL_MATRIX[3]);

    MODELVIEW_MATRIX = MODELVIEW_MATRIX * mat4(
            vec4(length(MODEL_MATRIX[0].xyz), 0.0, 0.0, 0.0),
            vec4(0.0, length(MODEL_MATRIX[1].xyz), 0.0, 0.0),
            vec4(0.0, 0.0, length(MODEL_MATRIX[2].xyz), 0.0),
            vec4(0.0, 0.0, 0.0, 1.0));
    MODELVIEW_NORMAL_MATRIX = mat3(MODELVIEW_MATRIX);
    
    // 2. Curved World Calculation
    vec3 world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
    vec3 cam_to_vertex = world_pos - CAMERA_POSITION_WORLD;
    
    float raw_dist = -cam_to_vertex.z;
    float effect_dist = max(0.0, raw_dist - global_curve_start); 
    float curve_factor = effect_dist * effect_dist;
    
    vec3 offset = vec3(
        curve_factor * global_curve_intensity.x,
        curve_factor * global_curve_intensity.y,
        0.0
    );
    
    VERTEX += (inverse(MODEL_MATRIX) * vec4(offset, 0.0)).xyz;

    // Pass screen position to fragment to trace depth edge thresholds
    v_screen_pos = PROJECTION_MATRIX * MODELVIEW_MATRIX * vec4(VERTEX, 1.0);
}

void fragment() {
    // Read the main texture map color
    vec4 tex_color = texture(texture_albedo, UV) * albedo;
    
    // Calculate the physical screen edge thickness using derivative math
    vec2 screen_uv = (v_screen_pos.xy / v_screen_pos.w) * 0.5 + 0.5;
    
    // Check pixel density changes along the edge of the text mesh geometry
    float edge_x = fwidth(screen_uv.x) * outline_size;
    float edge_y = fwidth(screen_uv.y) * outline_size;
    
    // Sample texture boundaries 
    float w_left   = texture(texture_albedo, UV + vec2(-edge_x, 0.0)).a;
    float w_right  = texture(texture_albedo, UV + vec2(edge_x, 0.0)).a;
    float w_top    = texture(texture_albedo, UV + vec2(0.0, -edge_y)).a;
    float w_bottom = texture(texture_albedo, UV + vec2(0.0, edge_y)).a;
    
    // Check if the current pixel is an internal surface edge or mesh silhouette border
    float total_alpha = max(max(w_left, w_right), max(w_top, w_bottom));
    
    // Compute outline mask based on geometric UV edge density
    float edge_factor = 1.0 - (dFdx(UV.x) * dFdy(UV.y));
    float is_edge = smoothstep(0.4, 0.5, length(vec2(dFdx(UV.x), dFdy(UV.y))) * outline_size * 100.0);
    
    // Blend final outputs seamlessly
    vec3 mixed_color = mix(tex_color.rgb, outline_color.rgb, is_edge);
    
    ALBEDO = mixed_color;
    ALPHA = max(tex_color.a, is_edge * outline_color.a);
}
