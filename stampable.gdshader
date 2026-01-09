shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back;

uniform sampler2D mask_tex : source_color;

// How deep it looks (purely shading illusion)
uniform float fake_depth = 0.08;

// Edge width in UV units (tweak per asset)
uniform float edge_uv = 0.02;

// Interior “rock/dirt” tint
uniform vec3 interior_albedo : source_color = vec3(0.08, 0.06, 0.05);
uniform float interior_roughness = 1.0;

float sample_mask(vec2 uv) {
    return texture(mask_tex, uv).r; // 0 solid, 1 carved
}

void fragment() {
    float m = sample_mask(UV);

    // If you still want an actual hole (see-through), keep discard.
    // If you want "dent" instead of "hole", remove discard and just shade.
    // discard makes the cut harsh but believable for "chunk removed".
    if (m > 0.95) discard;

    // Approximate mask gradient (for edge normal / bevel)
    float mx1 = sample_mask(UV + vec2(edge_uv, 0.0));
    float mx0 = sample_mask(UV - vec2(edge_uv, 0.0));
    float my1 = sample_mask(UV + vec2(0.0, edge_uv));
    float my0 = sample_mask(UV - vec2(0.0, edge_uv));
    vec2 grad = vec2(mx1 - mx0, my1 - my0);

    // Edge factor: strongest where mask transitions
    float edge = clamp(length(grad) * 6.0, 0.0, 1.0);

    // Fake a beveled normal (push normal “inward” along gradient)
    // Tangent-space normal approximation using gradient
    vec3 n_tangent = normalize(vec3(-grad.x, -grad.y, 1.0));
    NORMAL_MAP = n_tangent;           // Godot will treat this as tangent-space normal
    NORMAL_MAP_DEPTH = edge * 1.0;

    // Interior shading blend near the cut
    float interior = smoothstep(0.4, 0.95, m); // blend toward interior as m increases

    // Darken + roughen toward the interior, plus slight AO at the edge
    vec3 base = ALBEDO;
    ALBEDO = mix(base, interior_albedo, interior);
    ROUGHNESS = mix(ROUGHNESS, interior_roughness, interior);

    // Fake occlusion where edge is (adds “depth”)
    AO = mix(AO, 0.4, edge * 0.8);

    // Push shading darker just inside the edge (bevel shadow)
    ALBEDO *= 1.0 - edge * 0.25;
}
