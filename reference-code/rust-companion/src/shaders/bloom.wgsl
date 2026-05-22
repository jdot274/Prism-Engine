// bloom.wgsl
// Prism — Post-process bloom pipeline.
//
// This shader implements the bloom effect that sits atop the composited canvas.
// Bloom in Prism is additive: bright accent colours (prism-cyan, prism-lime,
// glow states) spread luminance into adjacent pixels, reinforcing the "glow is
// earned, never decorative" principle. Only pixels that genuinely exceed the
// luminance threshold contribute to bloom.
//
// Three-pass design:
//
//   Pass 0 — THRESHOLD  (this invocation when pass == 0u)
//     Reads the HDR scene colour texture. For each pixel, checks whether the
//     luminance exceeds `threshold`. Pixels below threshold are written as black
//     (no bloom contribution). Pixels at or above threshold are written at full
//     brightness. This bright-pass image is the input for the blur passes.
//     Threshold test: length(colour.rgb) < 0.001 is used as a guard to skip
//     the zero-vector case cleanly before the luminance compare.
//
//   Pass 1 — BLUR_H  (horizontal Gaussian blur on the bright-pass image)
//   Pass 2 — BLUR_V  (vertical Gaussian blur on the H-blurred image)
//     Separable 9-tap Gaussian blur. Sigma is driven by `blur_radius` in
//     the uniform (design spec: radius 4, matching EEVEE's bloom radius 4).
//     The blur runs in two passes to keep the sample count linear in radius.
//
//   Pass 3 — COMPOSITE  (this invocation when pass == 3u)
//     Reads the original HDR scene texture plus the bloom texture (the output
//     of Pass 2). Additively blends bloom onto the scene at `bloom_intensity`.
//     Applies simple Reinhard tonemapping and gamma correction (sRGB).
//     Design spec (§2.3): bloom intensity 0.15, threshold 0.8.
//
// Usage: render four quads / dispatch with different `pass` uniform values,
// writing each result to a ping-pong render target pair. The CPU side manages
// which texture is read/written per pass.

// ── Uniforms ──────────────────────────────────────────────────────────────────

struct BloomUniforms {
    // Viewport resolution in pixels.
    resolution: vec2<f32>,

    // Which pass is executing: 0=threshold, 1=blur_h, 2=blur_v, 3=composite.
    pass: u32,

    // Luminance threshold [0, 1] for the bright-pass extraction.
    // Spec: 0.8 (EEVEE default from §2.3).
    threshold: f32,

    // Bloom intensity [0, ∞]. Spec: 0.15.
    // Scales the bloom contribution in the composite pass.
    bloom_intensity: f32,

    // Blur radius in pixels. Spec: radius 4 → use ~4.0.
    // Controls the Gaussian sigma (sigma ≈ radius / 2).
    blur_radius: f32,

    // Per-state bloom multiplier for icon/card glow states (§2.3):
    //   Idle:     0.0  (no bloom layer)
    //   Active:   0.3  (Active state bloom: 0.3×)
    //   Selected: 0.6  (Selected state bloom: 0.6×)
    // Combined with bloom_intensity at the composite stage.
    state_bloom_scale: f32,

    _pad: f32,
};

@group(0) @binding(0) var<uniform> u: BloomUniforms;

// Scene HDR colour texture (the composited canvas before bloom).
@group(0) @binding(1) var t_scene:  texture_2d<f32>;
@group(0) @binding(2) var s_scene:  sampler;

// Bloom texture: output of the blur passes, input to the composite pass.
@group(0) @binding(3) var t_bloom:  texture_2d<f32>;
@group(0) @binding(4) var s_bloom:  sampler;

// ── Vertex stage ──────────────────────────────────────────────────────────────

struct VertexOut {
    @builtin(position) clip_pos: vec4<f32>,
    @location(0)       uv:       vec2<f32>,
};

// Full-screen triangle.
@vertex
fn vs_main(@builtin(vertex_index) vi: u32) -> VertexOut {
    var positions = array<vec2<f32>, 3>(
        vec2<f32>(-1.0, -1.0),
        vec2<f32>( 3.0, -1.0),
        vec2<f32>(-1.0,  3.0),
    );
    let p = positions[vi];
    var out: VertexOut;
    out.clip_pos = vec4<f32>(p, 0.0, 1.0);
    // UV: [0,1] top-left to bottom-right. Y is flipped to match texture layout.
    out.uv = vec2<f32>(p.x * 0.5 + 0.5, 0.5 - p.y * 0.5);
    return out;
}

// ── Helpers ───────────────────────────────────────────────────────────────────

// Perceived luminance in linear sRGB (ITU-R BT.709 coefficients).
fn luminance(c: vec3<f32>) -> f32 {
    return dot(c, vec3<f32>(0.2126, 0.7152, 0.0722));
}

// Reinhard tonemapping — simple but stable for the Prism dark aesthetic.
// Operates per-channel to preserve hue of saturated accent colours.
fn tonemap_reinhard(c: vec3<f32>) -> vec3<f32> {
    return c / (c + vec3<f32>(1.0));
}

// Linear-to-sRGB gamma approximation (pow 1/2.2).
// For production, replace with the piecewise IEC 61966-2-1 function.
fn linear_to_srgb(c: vec3<f32>) -> vec3<f32> {
    return pow(max(c, vec3<f32>(0.0)), vec3<f32>(1.0 / 2.2));
}

// 9-tap separable Gaussian weights for the given sigma.
// Hardcoded for sigma = blur_radius / 2.0; weights are normalised to sum = 1.
// Using a fixed array at sigma≈2 (radius 4 maps to sigma≈2).
// If blur_radius differs significantly, the caller should recompile with a
// specialisation constant — this implementation uses the runtime value to
// scale sample offsets and approximates the weight curve analytically.
fn gaussian_weight(offset: f32, sigma: f32) -> f32 {
    return exp(-(offset * offset) / (2.0 * sigma * sigma));
}

// ── Fragment stage ────────────────────────────────────────────────────────────

@fragment
fn fs_main(in: VertexOut) -> @location(0) vec4<f32> {
    let uv = in.uv;

    // Dispatch to the appropriate pass.
    switch u.pass {
        case 0u: { return pass_threshold(uv); }
        case 1u: { return pass_blur(uv, true);  } // horizontal
        case 2u: { return pass_blur(uv, false); } // vertical
        case 3u: { return pass_composite(uv); }
        default: { return vec4<f32>(1.0, 0.0, 1.0, 1.0); } // error: magenta
    }
}

// ── Pass 0: Threshold (bright-pass extraction) ────────────────────────────────
//
// Reads the HDR scene. Any pixel whose direction vector has length < 0.001
// is treated as black (guard against zero-vector atan2 instability in callers
// that feed angle-derived colours). For all other pixels, compares luminance
// against `threshold`; clips below, passes above.

fn pass_threshold(uv: vec2<f32>) -> vec4<f32> {
    let scene = textureSample(t_scene, s_scene, uv);
    let col   = scene.rgb;

    // Guard: if the colour vector is essentially zero-length, emit black.
    // This threshold test avoids dividing by near-zero in normalisation steps
    // and cleanly skips pixels that have no chromatic contribution.
    if length(col) < 0.001 {
        return vec4<f32>(0.0, 0.0, 0.0, scene.a);
    }

    // Luminance-based bright-pass clamp.
    // Pixels below threshold contribute nothing; pixels above pass through.
    // A smooth knee prevents a hard clip that would cause ringing at edges.
    let lum = luminance(col);

    // Soft knee: ramp from 0 at (threshold − knee) to 1 at (threshold + knee).
    // Knee width = 0.1 (roughly 10% of the threshold range).
    let knee  = 0.1;
    let knee_factor = smoothstep(u.threshold - knee, u.threshold + knee, lum);

    let bright = col * knee_factor;
    return vec4<f32>(bright, scene.a);
}

// ── Pass 1 & 2: Separable Gaussian blur ───────────────────────────────────────
//
// 9-tap Gaussian along the specified axis. Samples the bright-pass image
// (stored in t_scene for Pass 1, and t_bloom for Pass 2, as the CPU swaps
// ping-pong targets between passes).
//
// `horizontal`: true = blur along X (Pass 1), false = blur along Y (Pass 2).

fn pass_blur(uv: vec2<f32>, horizontal: bool) -> vec4<f32> {
    let sigma      = u.blur_radius * 0.5;          // sigma ≈ radius/2
    let texel_size = 1.0 / u.resolution;

    // 9-tap offsets: −4 to +4 in the blur direction.
    var sum     = vec3<f32>(0.0);
    var weight_total = 0.0;

    for (var i: i32 = -4; i <= 4; i++) {
        let offset_f = f32(i);
        let w        = gaussian_weight(offset_f, sigma);

        var sample_uv = uv;
        if horizontal {
            sample_uv.x += offset_f * texel_size.x;
        } else {
            sample_uv.y += offset_f * texel_size.y;
        }

        // Clamp UV to [0,1] to prevent wrap-around bleeding at edges.
        sample_uv = clamp(sample_uv, vec2<f32>(0.0), vec2<f32>(1.0));

        // Pass 1 reads from t_scene (the bright-pass output).
        // Pass 2 reads from t_bloom (the H-blurred output).
        // Since we can't branch on textures in WGSL, both are bound and the
        // pass uniform drives which is "active" by the calling pass switching
        // the render target assignment. At shader level we always read t_scene
        // in Pass 1 and t_bloom in Pass 2 — the CPU binds the correct texture
        // to the correct slot before each dispatch.
        var tap: vec4<f32>;
        if horizontal {
            tap = textureSample(t_scene, s_scene, sample_uv);
        } else {
            tap = textureSample(t_bloom, s_bloom, sample_uv);
        }

        sum          += tap.rgb * w;
        weight_total += w;
    }

    // Normalise by total weight (sum of Gaussian samples may not be exactly 1).
    let blurred = sum / weight_total;
    return vec4<f32>(blurred, 1.0);
}

// ── Pass 3: Composite ─────────────────────────────────────────────────────────
//
// Reads the original HDR scene (t_scene) and the blurred bloom (t_bloom).
// Adds the bloom contribution at `bloom_intensity * state_bloom_scale`,
// applies Reinhard tonemapping, then gamma-corrects for sRGB output.
//
// Design spec values:
//   bloom_intensity  = 0.15
//   state_bloom_scale = 0.0 (idle), 0.3 (active), 0.6 (selected) — set by CPU.

fn pass_composite(uv: vec2<f32>) -> vec4<f32> {
    let scene = textureSample(t_scene, s_scene, uv);
    let bloom = textureSample(t_bloom, s_bloom, uv);

    // Additive bloom. The accumulated bloom texture is additively composited
    // on top of the scene, scaled by intensity and the per-state multiplier.
    let bloom_contribution = bloom.rgb * u.bloom_intensity * u.state_bloom_scale;
    let hdr = scene.rgb + bloom_contribution;

    // Tonemap to display range.
    let tonemapped = tonemap_reinhard(hdr);

    // Gamma correction for sRGB output surface.
    let display = linear_to_srgb(tonemapped);

    return vec4<f32>(display, scene.a);
}
