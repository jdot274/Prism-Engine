// card.wgsl
// Prism — Floating card renderer.
//
// Each Prism tool lives in a 480 × 480dp floating square card. This shader
// is responsible for the card body, border, inner glow (active state), and
// the SDF-based outer glow that replaces a traditional drop shadow. It does
// NOT render card content (header bar, controls, text) — those are composited
// separately. This pass outputs the card surface quad at the correct elevation.
//
// Shadow / depth model (spec §3.4):
//   Layer 1  ambient: 0px 4px  blur 20px spread −2px  black 60%
//   Layer 2  contact: 0px 2px  blur 6px  spread 0px   black 80%
//   Layer 3  active glow: 0px 0px blur 60px spread −10px  prism-cyan 12%
//
// Implementation: instead of multiple texture-space blur passes, we evaluate
// the shadow analytically using the SDF of the rounded rectangle. The SDF
// value drives a smooth Gaussian-like falloff that closely approximates a
// CSS box-shadow. This keeps the card shader self-contained with no auxiliary
// render targets for the shadow itself.
//
// SDF outer glow replaces offset shadow: the spec describes the shadow as
// elevation-communicating depth, not as a hard directional cast. An SDF glow
// centred on the card perimeter achieves the same read while being cheaper
// (single pass) and more faithful to the "glow is earned, never decorative"
// principle — the glow comes from the card edge, not from a fake light source.

// ── Uniforms ──────────────────────────────────────────────────────────────────

struct CardUniforms {
    // Position of the card's top-left corner in screen pixels.
    position: vec2<f32>,

    // Card dimensions in screen pixels (spec: 480 × 480dp, scaled by DPI).
    size: vec2<f32>,

    // Corner radius in screen pixels (spec: 16dp).
    corner_radius: f32,

    // Card state: 0 = default, 1 = focused, 2 = active.
    // Controls border colour and whether the active inner/outer glows render.
    state: f32,

    // Overall card opacity [0.0 … 1.0] (used during enter/exit animations).
    // At rest: 1.0.
    opacity: f32,

    // Active glow pulse intensity [0.0 … 1.0].
    // Driven by the CPU-side spring/tween system during processing state.
    // 0.0 = static active glow (12% opacity), 1.0 = peak pulse (22% opacity).
    glow_pulse: f32,

    // Viewport resolution in physical pixels.
    resolution: vec2<f32>,

    _pad: vec2<f32>,
};

@group(0) @binding(0) var<uniform> u: CardUniforms;

// ── Vertex stage ──────────────────────────────────────────────────────────────

struct VertexOut {
    @builtin(position) clip_pos: vec4<f32>,
    // Screen-space pixel position (for SDF evaluation in fragment stage).
    @location(0) screen_px: vec2<f32>,
};

// Full-screen triangle; the fragment stage clips to the card bounds via SDF.
// This avoids any geometry changes when the card moves or resizes.
@vertex
fn vs_main(@builtin(vertex_index) vi: u32) -> VertexOut {
    var positions = array<vec2<f32>, 3>(
        vec2<f32>(-1.0, -1.0),
        vec2<f32>( 3.0, -1.0),
        vec2<f32>(-1.0,  3.0),
    );
    let p = positions[vi];
    var out: VertexOut;
    out.clip_pos  = vec4<f32>(p, 0.0, 1.0);
    // Convert clip space to screen pixels.
    out.screen_px = (p * 0.5 + 0.5) * u.resolution;
    // Y is flipped: clip +1 = screen top (y=0).
    out.screen_px.y = u.resolution.y - out.screen_px.y;
    return out;
}

// ── SDF helpers ───────────────────────────────────────────────────────────────

// Signed distance to a rounded rectangle.
//   p      — query point relative to the rect centre
//   half   — half-extents of the rect (width/2, height/2)
//   radius — corner radius
// Returns negative inside, 0 on boundary, positive outside.
fn sdf_rounded_rect(p: vec2<f32>, half: vec2<f32>, radius: f32) -> f32 {
    let q = abs(p) - half + radius;
    return length(max(q, vec2<f32>(0.0))) + min(max(q.x, q.y), 0.0) - radius;
}

// Gaussian-like falloff from an SDF distance value.
// width controls the sigma of the spread (pixels).
fn shadow_falloff(dist: f32, width: f32) -> f32 {
    // Approximate a Gaussian with a smooth-step ramp.
    // dist > 0 = outside the shape; we want 0 at dist=0, rising then falling.
    // For a box-shadow we want: bright at the edge, falling outward.
    let t = clamp(dist / width, 0.0, 1.0);
    return (1.0 - t) * (1.0 - t);
}

// ── Colour constants (linear sRGB) ────────────────────────────────────────────
//
// All hex values from visual-identity.md, converted to linear sRGB.
// Conversion: linear = (sRGB/255)^2.2  (approximate; use exact formula in prod)
//
//   Surface 1   #111622  → (0.00368, 0.00640, 0.01325)  card body fill
//   Surface 2   #161D2E  → (0.00606, 0.01063, 0.02712)  header bar
//   edge-subtle #1F2B42  → (0.01271, 0.02526, 0.05765)  default border
//   edge-accent #2A3A58  → (0.02584, 0.04807, 0.10625)  focused border
//   cyan-dim    #007880  → (0.0,     0.21586, 0.24620)  active border
//   cyan-base   #00F5FF  → (0.0,     0.91371, 1.0     )  active glow / layer 3
//   black                → (0, 0, 0)                     shadow layers 1 & 2

// Card body fill: Surface 1 at 92% opacity (spec §3.1).
const CARD_FILL:       vec4<f32> = vec4<f32>(0.00368, 0.00640, 0.01325, 0.92);

// Border colours indexed by state.
// state 0 = default: edge-subtle 60%
const BORDER_DEFAULT:  vec4<f32> = vec4<f32>(0.01271, 0.02526, 0.05765, 0.60);
// state 1 = focused: edge-accent 100%
const BORDER_FOCUSED:  vec4<f32> = vec4<f32>(0.02584, 0.04807, 0.10625, 1.00);
// state 2 = active: cyan-dim 100%
const BORDER_ACTIVE:   vec4<f32> = vec4<f32>(0.0,     0.21586, 0.24620, 1.00);

// Active inner glow: #00F5FF18 = prism-cyan at alpha 0x18/0xFF ≈ 9.4%
const INNER_GLOW_COL:  vec3<f32> = vec3<f32>(0.0, 0.91371, 1.0);
const INNER_GLOW_A:    f32       = 0.094;

// Shadow Layer 1 — ambient: black 60%, broad (blur ≈ 20px at spec scale).
const SHADOW1_A:       f32 = 0.60;
const SHADOW1_BLUR:    f32 = 20.0;   // pixels
const SHADOW1_OFFSET:  vec2<f32> = vec2<f32>(0.0, 4.0);
const SHADOW1_SPREAD:  f32 = -2.0;

// Shadow Layer 2 — contact: black 80%, tight (blur ≈ 6px).
const SHADOW2_A:       f32 = 0.80;
const SHADOW2_BLUR:    f32 = 6.0;
const SHADOW2_OFFSET:  vec2<f32> = vec2<f32>(0.0, 2.0);
const SHADOW2_SPREAD:  f32 = 0.0;

// Shadow Layer 3 — active glow: prism-cyan 12% at rest, 22% at glow_pulse=1.
// blur ≈ 60px, spread = -10px.
const SHADOW3_COL:     vec3<f32> = vec3<f32>(0.0, 0.91371, 1.0);
const SHADOW3_A_MIN:   f32 = 0.12;
const SHADOW3_A_MAX:   f32 = 0.22;
const SHADOW3_BLUR:    f32 = 60.0;
const SHADOW3_SPREAD:  f32 = -10.0;

// Border width in pixels.
const BORDER_PX:       f32 = 1.0;

// ── Fragment stage ────────────────────────────────────────────────────────────

@fragment
fn fs_main(in: VertexOut) -> @location(0) vec4<f32> {
    let px = in.screen_px;

    // Card geometry in screen space.
    let card_min  = u.position;
    let card_max  = u.position + u.size;
    let card_half = u.size * 0.5;
    let card_ctr  = u.position + card_half;
    let r         = u.corner_radius;

    // SDF of the card body (positive outside, negative inside).
    let body_sdf  = sdf_rounded_rect(px - card_ctr, card_half, r);

    // ── Shadow accumulation ───────────────────────────────────────────────────
    // Shadow layers are evaluated before the card fill so they appear beneath.

    var shadow_colour = vec3<f32>(0.0);
    var shadow_alpha  = 0.0;

    // Layer 1 — ambient (0px, 4px offset, blur 20px, spread −2px, black 60%).
    {
        let spread_half = card_half + SHADOW1_SPREAD;
        let offset_ctr  = card_ctr + SHADOW1_OFFSET;
        let d = sdf_rounded_rect(px - offset_ctr, spread_half, r);
        // Shadow region: outside the spread-contracted shape (d > 0).
        let a = shadow_falloff(max(d, 0.0), SHADOW1_BLUR) * SHADOW1_A;
        // Additive accumulation; we'll normalise later.
        shadow_alpha = max(shadow_alpha, a);
    }

    // Layer 2 — contact (0px, 2px offset, blur 6px, spread 0px, black 80%).
    {
        let spread_half = card_half + SHADOW2_SPREAD;
        let offset_ctr  = card_ctr + SHADOW2_OFFSET;
        let d = sdf_rounded_rect(px - offset_ctr, spread_half, r);
        let a = shadow_falloff(max(d, 0.0), SHADOW2_BLUR) * SHADOW2_A;
        shadow_alpha = max(shadow_alpha, a);
    }

    // Layer 3 — active glow (0px 0px, blur 60px, spread −10px, prism-cyan).
    // Only renders when state == 2 (active).
    var glow3_alpha = 0.0;
    if u.state >= 2.0 {
        let spread_half = card_half + SHADOW3_SPREAD;
        let d = sdf_rounded_rect(px - card_ctr, spread_half, r);
        // The outer glow radiates outward from the (spread-contracted) edge.
        let dist_out = max(d, 0.0);
        let glow_a   = shadow_falloff(dist_out, SHADOW3_BLUR);
        let pulse_a  = mix(SHADOW3_A_MIN, SHADOW3_A_MAX, u.glow_pulse);
        glow3_alpha  = glow_a * pulse_a;
        shadow_colour = SHADOW3_COL;
    }

    // ── Card fill ─────────────────────────────────────────────────────────────
    // Anti-aliased coverage of the rounded rectangle interior.
    // body_sdf < 0  → inside card,  > 0 → outside.
    let aa_px    = 1.0; // one pixel for anti-aliasing
    let coverage = 1.0 - smoothstep(-aa_px, aa_px, body_sdf);

    var fill_col = CARD_FILL.rgb;
    var fill_a   = CARD_FILL.a * coverage;

    // ── Inner glow (active state) ─────────────────────────────────────────────
    // Spec: inset box-shadow, colour #00F5FF18, blur 32px.
    // We simulate this as a fade from the card edge inward.
    if u.state >= 2.0 && coverage > 0.0 {
        // Inward distance from the card edge (positive inside).
        let inward = -body_sdf;
        let inner_t = clamp(inward / 32.0, 0.0, 1.0);
        // The glow is strongest at the border, falling off inward.
        let inner_a = (1.0 - inner_t) * INNER_GLOW_A * coverage;
        // Blend inner glow over fill using additive-alpha approach.
        fill_col = fill_col + INNER_GLOW_COL * inner_a;
        fill_a   = min(fill_a + inner_a, 1.0);
    }

    // ── Border ────────────────────────────────────────────────────────────────
    // A 1px border drawn as an SDF ring straddling the card edge.
    let border_sdf  = abs(body_sdf) - BORDER_PX * 0.5;
    let border_cov  = 1.0 - smoothstep(0.0, aa_px, border_sdf);

    var border: vec4<f32>;
    if u.state >= 2.0 {
        border = BORDER_ACTIVE;
    } else if u.state >= 1.0 {
        border = BORDER_FOCUSED;
    } else {
        border = BORDER_DEFAULT;
    }

    // Blend border over fill.
    let b_a = border.a * border_cov;
    fill_col = mix(fill_col, border.rgb, b_a);
    fill_a   = max(fill_a, b_a * coverage);

    // ── Composite: shadow → glow → card ──────────────────────────────────────
    // Only pixels outside the card body contribute shadow/glow.
    // Inside the card the fill dominates.
    var out_colour = vec4<f32>(0.0);

    // Start with the black shadow beneath everything (outside card).
    let shadow_outside = shadow_alpha * (1.0 - coverage);
    out_colour = vec4<f32>(0.0, 0.0, 0.0, shadow_outside);

    // Cyan outer glow (active state only, outside card).
    let glow_outside = glow3_alpha * (1.0 - coverage);
    // Additive blend of glow over the dark shadow.
    out_colour.rgb += SHADOW3_COL * glow_outside;
    out_colour.a    = max(out_colour.a, glow_outside);

    // Card fill on top (inside card).
    // Standard over-compositing: out = src + dst*(1-src.a)
    out_colour.rgb = fill_col * fill_a + out_colour.rgb * (1.0 - fill_a);
    out_colour.a   = fill_a + out_colour.a * (1.0 - fill_a);

    // Apply card-level opacity (entrance/exit animation).
    out_colour.a *= u.opacity;

    return out_colour;
}
