shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

// Posterization Controls
uniform int levels : hint_range(2, 256) = 8;
uniform int levels_r : hint_range(2, 256) = 8;
uniform int levels_g : hint_range(2, 256) = 8;
uniform int levels_b : hint_range(2, 256) = 8;
uniform bool use_separate_levels = false;
uniform bool enable_posterization = true;

// Color Adjustments
uniform float brightness : hint_range(0.0, 2.0) = 1.0;
uniform float contrast : hint_range(0.0, 2.0) = 1.0;
uniform float saturation : hint_range(0.0, 2.0) = 1.0;
uniform float gamma : hint_range(0.1, 3.0) = 1.0;

// Tinting
uniform vec4 tint_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float tint_strength : hint_range(0.0, 1.0) = 0.0;

// Edge Detection (optional)
uniform float edge_threshold : hint_range(0.0, 1.0) = 0.1;
uniform bool enable_edge_detection = false;

void fragment() {
	// Sample the screen texture
	vec3 color = texture(SCREEN_TEXTURE, SCREEN_UV).rgb;
	
	// Apply brightness
	color *= brightness;
	
	// Apply gamma correction
	color = pow(max(color, vec3(0.0)), vec3(1.0 / gamma));
	
	// Apply contrast
	float gray = dot(color, vec3(0.299, 0.587, 0.114));
	color = mix(vec3(gray), color, contrast);
	
	// Apply saturation
	float saturation_factor = dot(color, vec3(0.299, 0.587, 0.114));
	color = mix(vec3(saturation_factor), color, saturation);
	
	// Optional edge detection
	if (enable_edge_detection) {
		// Use a small fixed offset for edge detection
		vec2 offset = vec2(0.001, 0.001);
		vec3 color_l = texture(SCREEN_TEXTURE, SCREEN_UV - vec2(offset.x, 0.0)).rgb;
		vec3 color_r = texture(SCREEN_TEXTURE, SCREEN_UV + vec2(offset.x, 0.0)).rgb;
		vec3 color_u = texture(SCREEN_TEXTURE, SCREEN_UV - vec2(0.0, offset.y)).rgb;
		vec3 color_d = texture(SCREEN_TEXTURE, SCREEN_UV + vec2(0.0, offset.y)).rgb;
		
		vec3 edge = abs(color - color_l) + abs(color - color_r) + abs(color - color_u) + abs(color - color_d);
		float edge_strength = length(edge) / 3.0;
		
		if (edge_strength > edge_threshold) {
			// Enhance edges slightly
			color = mix(color, color * 1.2, 0.3);
		}
	}
	
	// Apply posterization
	if (enable_posterization) {
		if (use_separate_levels) {
			// Per-channel posterization
			color.r = floor(color.r * float(levels_r)) / float(levels_r);
			color.g = floor(color.g * float(levels_g)) / float(levels_g);
			color.b = floor(color.b * float(levels_b)) / float(levels_b);
		} else {
			// Uniform posterization
			color = floor(color * float(levels)) / float(levels);
		}
	}
	
	// Apply color tinting
	color = mix(color, color * tint_color.rgb, tint_strength);
	
	COLOR = vec4(color, 1.0);
}

