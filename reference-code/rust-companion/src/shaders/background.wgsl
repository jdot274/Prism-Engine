// background.wgsl
// Prism — Infinite canvas background shader.
//
// Renders the "void" canvas layer: near-black with a cool blue undertone
// (#080A0E, hsl(220, 30%, 5%)) so the surface reads as anodized metal or
// tempered glass rather than a flat hole in the screen.
//
// The subtle radial vignette deepens toward the corners, reinforcing the
// sense of depth without introducing any visible color shift at center.
// A barely-perceptible noise grain at ~1/255 luminance prevents gradient
// banding on large dark fields.
//
// No lighting calculations. This pass owns the base layer and must be
// drawn first; everything else composites on top.

// ── Uniforms ─────────────────────────────────────────────────────────────────

struct CanvasUniforms {
    // Viewport resolution in physical pixels (width, height).
    resolution: vec2<f32>,

    // Scrolled origin of the canvas in world-space units. Passed through to
    // any future grid-overlay extension; unused by this shader in isolation.
    scroll_offset: vec2<f32>,

    // Time in seconds (used for the noise seed to allow temporal dithering
    // if the caller opts in; keep at 0.0 for a static frame).
    time: f32,

    // Vignette strength [0.0 … 1.0]. Design spec default: 0.35.
    // 0.0 = no vignette, 1.0 = deep corner crush.
    vignette_strength: f32,

    // Grain amplitude [0.0 … 1.0]. Design spec default: 0.012 (≈1/80 stop).
    // Keeps the large dark canvas from banding on high-bit displays.
    grain_amplitude: f32,

    _pad: vec2<f32>,
};

@group(0) @binding(0) var<uniform> u: CanvasUniforms;

// ── Vertex stage ──────────────────────────────────────────────────────────────

struct VertexOut {
    @builtin(position) clip_pos: vec4<f32>,
    // UV in [0, 1] from top-left to bottom-right, for vignette math.
    @location(0) uv: vec2<f32>,
};

// Full-screen triangle: three hard-coded vertices cover the clip-space quad
// without a vertex buffer. Draw with 3 vertices, no index buffer.
@vertex
fn vs_main(@builtin(vertex_index) vi: u32) -> VertexOut {
    // Positions for a single oversized triangle that covers [-1, 1] clip space.
    var positions = array<vec2<f32>, 3>(
        vec2<f32>(-1.0, -1.0),
        vec2<f32>( 3.0, -1.0),
        vec2<f32>(-1.0,  3.0),
    );
    let p = positions[vi];
    var out: VertexOut;
    out.clip_pos = vec4<f32>(p, 0.0, 1.0);
    // Map clip-space [-1,1] → UV [0,1], Y flipped to match texture convention.
    out.uv = vec2<f32>(p.x * 0.5 + 0.5, 0.5 - p.y * 0.5);
    return out;
}

// ── Helpers ───────────────────────────────────────────────────────────────────

// Hash-based pseudo-random scalar in [0, 1). Fast, no texture lookup.
fn hash_f32(seed: vec2<f32>) -> f32 {
    let k = vec2<f32>(127.1, 311.7);
    return fract(sin(dot(seed, k)) * 43758.5453123);
}

// ── Fragment stage ────────────────────────────────────────────────────────────

@fragment
fn fs_main(in: VertexOut) -> @location(0) vec4<f32> {
    // ── 1. Base canvas colour ─────────────────────────────────────────────────
    // #080A0E — hsl(220, 30%, 5%): barely-perceptible cool blue undertone.
    // Stored in linear sRGB (gamma-decoded) for correct blending.
    // sRGB #080A0E → linear ≈ (0.0096, 0.0137, 0.0200)
    let base_linear = vec3<f32>(0.00968, 0.01368, 0.02002);

    // ── 2. Radial vignette ────────────────────────────────────────────────────
    // Centre-biased: uv (0.5, 0.5) is brightest; corners fall off.
    // We use a smooth power curve rather than a hard cosine to keep the
    // transition imperceptible over most of the canvas area.
    let centered = in.uv - vec2<f32>(0.5);
    // Aspect-corrected radius [0 … ~0.71 at corner].
    let aspect   = u.resolution.x / u.resolution.y;
    let r        = length(vec2<f32>(centered.x * aspect, centered.y));
    // Vignette factor: 1.0 at center, falling toward 0.0 at corners.
    let vignette = 1.0 - smoothstep(0.35, 0.85, r) * u.vignette_strength;

    var colour = base_linear * vignette;

    // ── 3. Noise grain ────────────────────────────────────────────────────────
    // Temporal dithering: seed changes each frame when time advances, which
    // breaks up static banding patterns on displays with limited bit depth.
    let noise_seed = in.uv + vec2<f32>(u.time * 0.017, u.time * 0.031);
    let grain      = (hash_f32(noise_seed) - 0.5) * u.grain_amplitude;
    // Add grain in linear space; it will be gamma-encoded by the surface.
    colour += grain;

    // Clamp to prevent negative values from the grain subtraction.
    colour = max(colour, vec3<f32>(0.0));

    return vec4<f32>(colour, 1.0);
}
