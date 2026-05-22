// color_wheel.wgsl
// Prism — HSL Color Wheel shader.
//
// Renders the 2D hue ring and the inner triangle that forms the saturation /
// lightness selection area for the 3D HSL Color Wheel tool (Tool #1, Tier 1).
//
// Layout (screen-space, centred on widget_centre):
//   Outer radius  (ring_radius_outer):  outer edge of the hue ring
//   Inner radius  (ring_radius_inner):  inner edge of the hue ring
//                                       = outer vertex of the SL triangle
//   Triangle:     equilateral, inscribed in the inner circle,
//                 rotated so the hue apex tracks the selected hue angle.
//
// Triangle colour map (spec §3 — Spec A HSL Sphere):
//   Apex (hue angle):     fully-saturated hue at L=0.5
//   Bottom-left vertex:   black  (S=*, L=0)
//   Bottom-right vertex:  white  (S=0, L=1)
//   Interior:             analytic HSL interpolation across barycentric coords.
//
// The analytic triangle approach computes the HSL value directly from the
// fragment's barycentric coordinates — no texture lookup, no CPU-side raster.
//
// Hue ring: each fragment's hue is derived from atan2(y, x) relative to the
// widget centre, converted to [0, 1], and fed into the hsl_to_rgb helper.
// The ring always shows L=0.5, S=1.0 so the pure hue reads clearly.

// ── Uniforms ──────────────────────────────────────────────────────────────────

struct WheelUniforms {
    // Centre of the widget in screen pixels.
    centre: vec2<f32>,

    // Outer radius of the hue ring in pixels (design intent: ≈120dp).
    ring_radius_outer: f32,

    // Inner radius of the hue ring in pixels (design intent: ≈96dp).
    // This is also the circumradius of the SL triangle.
    ring_radius_inner: f32,

    // Currently selected hue in [0, 1). Used to:
    //   1. Rotate the triangle apex to the selected hue.
    //   2. Draw the selection dot on the ring.
    //   3. Tint the selection cursor on the triangle.
    hue: f32,

    // Currently selected saturation in [0, 1].
    saturation: f32,

    // Currently selected lightness in [0, 1].
    lightness: f32,

    // Anti-alias feather width in pixels. Use 1.5 for MSAA-off, 0.75 with MSAA.
    aa_width: f32,

    // Soft edge width of the hue ring fade (inner and outer edges), pixels.
    ring_edge_softness: f32,

    // Selection cursor dot radius in pixels (the white dot on the ring / triangle).
    cursor_radius: f32,
};

@group(0) @binding(0) var<uniform> u: WheelUniforms;

// ── Vertex stage ──────────────────────────────────────────────────────────────

struct VertexOut {
    @builtin(position) clip_pos:  vec4<f32>,
    @location(0)       screen_px: vec2<f32>,
};

// Full-screen triangle; fragment stage clips to the wheel bounds.
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
    // screen_px is passed as clip space → we reconstruct in fs using resolution.
    // We encode clip coords and convert in the fragment stage instead.
    out.screen_px = p; // raw clip, converted below via a global resolution uniform
    return out;
}

// ── Colour math ───────────────────────────────────────────────────────────────

// Standard HSL → linear RGB. H in [0,1), S and L in [0,1].
// Output is linear sRGB (no gamma correction applied here; surface handles it).
fn hsl_to_rgb(h: f32, s: f32, l: f32) -> vec3<f32> {
    let c  = (1.0 - abs(2.0 * l - 1.0)) * s;
    let h6 = h * 6.0;
    let x  = c * (1.0 - abs(h6 % 2.0 - 1.0));
    var rgb: vec3<f32>;
    let hi = u32(h6);
    switch hi {
        case 0u: { rgb = vec3<f32>(c, x, 0.0); }
        case 1u: { rgb = vec3<f32>(x, c, 0.0); }
        case 2u: { rgb = vec3<f32>(0.0, c, x); }
        case 3u: { rgb = vec3<f32>(0.0, x, c); }
        case 4u: { rgb = vec3<f32>(x, 0.0, c); }
        default: { rgb = vec3<f32>(c, 0.0, x); }
    }
    let m = l - c * 0.5;
    return rgb + m;
}

// Rotate a 2D vector by `angle` radians.
fn rotate2d(v: vec2<f32>, angle: f32) -> vec2<f32> {
    let s = sin(angle);
    let c = cos(angle);
    return vec2<f32>(v.x * c - v.y * s, v.x * s + v.y * c);
}

// Signed distance from point `p` to an infinite line through `a` toward `b`.
// Positive = left of the directed segment.
fn signed_dist_line(p: vec2<f32>, a: vec2<f32>, b: vec2<f32>) -> f32 {
    let ab = b - a;
    let ap = p - a;
    return (ab.x * ap.y - ab.y * ap.x) / length(ab);
}

// Barycentric coordinates of point p inside triangle (v0, v1, v2).
fn barycentric(p: vec2<f32>, v0: vec2<f32>, v1: vec2<f32>, v2: vec2<f32>) -> vec3<f32> {
    let denom = (v1.y - v2.y) * (v0.x - v2.x) + (v2.x - v1.x) * (v0.y - v2.y);
    let w0 = ((v1.y - v2.y) * (p.x - v2.x) + (v2.x - v1.x) * (p.y - v2.y)) / denom;
    let w1 = ((v2.y - v0.y) * (p.x - v2.x) + (v0.x - v2.x) * (p.y - v2.y)) / denom;
    let w2 = 1.0 - w0 - w1;
    return vec3<f32>(w0, w1, w2);
}

// SDF of an equilateral triangle centred at origin with circumradius `cr`.
// The apex points in the +Y direction before external rotation.
fn sdf_equilateral_triangle(p: vec2<f32>, circumradius: f32) -> f32 {
    // Three vertices of the equilateral triangle at unit circumradius.
    let v0 = vec2<f32>( 0.0,         circumradius);          // apex (top)
    let v1 = vec2<f32>(-circumradius * 0.8660254, -circumradius * 0.5); // bottom-left
    let v2 = vec2<f32>( circumradius * 0.8660254, -circumradius * 0.5); // bottom-right

    // SDF of the triangle: max signed distance to all three edges (inward normals).
    let d0 = signed_dist_line(p, v1, v0);
    let d1 = signed_dist_line(p, v2, v1);
    let d2 = signed_dist_line(p, v0, v2);
    // Inside when all three are positive (using right-hand winding).
    let inside = min(min(d0, d1), d2);
    return -inside; // negative inside, positive outside (standard SDF sign)
}

// ── Fragment stage ────────────────────────────────────────────────────────────

// Note: because this is a full-screen-triangle pass, we receive screen_px as
// clip coords. We need a resolution uniform to reconstruct pixel coords.
// For a self-contained design we embed resolution in WheelUniforms via a
// second binding, or (simpler) we pack it alongside the existing uniforms.
// Here we add it as a second uniform binding.

struct ResolutionUniform {
    resolution: vec2<f32>,
    _pad: vec2<f32>,
};

@group(0) @binding(1) var<uniform> res: ResolutionUniform;

@fragment
fn fs_main(in: VertexOut) -> @location(0) vec4<f32> {
    // Reconstruct screen pixel position from clip coords.
    let px = (in.screen_px * 0.5 + 0.5) * res.resolution;
    // p: position relative to wheel centre.
    let p  = px - u.centre;

    // Radial distance from centre.
    let r  = length(p);

    // Hue angle: atan2 in [−π, π] mapped to [0, 1).
    // Convention: hue=0 (red) is at the 3 o'clock position.
    let angle = atan2(p.y, p.x);
    let ring_hue = (angle / (2.0 * 3.14159265358979)) + 0.5; // [0,1)

    // ── Hue ring ──────────────────────────────────────────────────────────────
    // The ring covers ring_radius_inner ≤ r ≤ ring_radius_outer.
    // Softness applied at both inner and outer edges.
    let ring_outer_a = 1.0 - smoothstep(
        u.ring_radius_outer - u.ring_edge_softness,
        u.ring_radius_outer,
        r
    );
    let ring_inner_a = smoothstep(
        u.ring_radius_inner,
        u.ring_radius_inner + u.ring_edge_softness,
        r
    );
    let ring_mask = ring_outer_a * ring_inner_a;

    // Full-saturation, half-lightness for the hue ring.
    let ring_col = hsl_to_rgb(ring_hue, 1.0, 0.5);

    // ── SL triangle ──────────────────────────────────────────────────────────
    // Equilateral triangle inscribed in a circle of radius ring_radius_inner.
    // Apex rotates to track the selected hue angle (hue → angle in radians).
    // The hue apex is at angle = hue * 2π − π/2 (starting at top by default;
    // but we follow the ring convention: hue=0 is at 3 o'clock = 0 radians).
    let hue_angle_rad = u.hue * 2.0 * 3.14159265358979;

    // Rotate query point by the inverse of the hue angle to evaluate in the
    // canonical frame where the apex is at +Y.
    let p_local = rotate2d(p, -(hue_angle_rad - 1.5707963267948966)); // −(θ − π/2)

    let tri_sdf   = sdf_equilateral_triangle(p_local, u.ring_radius_inner);
    let tri_inner = tri_sdf < 0.0; // true if inside triangle

    // Compute barycentric coordinates for analytic HSL mapping.
    // Canonical triangle vertices (before hue rotation) at circumradius cr:
    let cr  = u.ring_radius_inner;
    let tv0 = vec2<f32>( 0.0,  cr);                           // apex: hue, S=1, L=0.5
    let tv1 = vec2<f32>(-cr * 0.8660254, -cr * 0.5);          // bottom-left: black S=*, L=0
    let tv2 = vec2<f32>( cr * 0.8660254, -cr * 0.5);          // bottom-right: white S=0, L=1

    let bary = barycentric(p_local, tv0, tv1, tv2);

    // Colour at each vertex:
    //   v0 = apex:         fully saturated hue at L=0.5
    //   v1 = bottom-left:  black (L=0)
    //   v2 = bottom-right: white (S=0, L=1)
    let col_apex  = hsl_to_rgb(u.hue, 1.0, 0.5);
    let col_black = vec3<f32>(0.0, 0.0, 0.0);
    let col_white = vec3<f32>(1.0, 1.0, 1.0);

    // Barycentric interpolation of vertex colours (analytic colour field).
    let tri_col = col_apex * bary.x + col_black * bary.y + col_white * bary.z;

    // Anti-aliased triangle edge mask.
    let tri_mask = 1.0 - smoothstep(-u.aa_width, u.aa_width, tri_sdf);

    // ── Selection cursors ─────────────────────────────────────────────────────
    // Ring cursor: white dot with dark outline at the current hue angle.
    let ring_cursor_pos = u.centre + vec2<f32>(
        cos(hue_angle_rad) * (u.ring_radius_inner + u.ring_radius_outer) * 0.5,
        sin(hue_angle_rad) * (u.ring_radius_inner + u.ring_radius_outer) * 0.5,
    );
    let ring_cursor_d = length(px - ring_cursor_pos);
    let ring_cursor_a = 1.0 - smoothstep(u.cursor_radius - u.aa_width, u.cursor_radius + u.aa_width, ring_cursor_d);
    // Outline ring.
    let ring_cursor_outline = 1.0 - smoothstep(u.cursor_radius + 1.0 - u.aa_width, u.cursor_radius + 2.0 + u.aa_width, ring_cursor_d);

    // Triangle cursor: white dot at the selected SL position in the triangle.
    // Reconstruct triangle cursor position from (hue, saturation, lightness).
    // Barycentric: w0=apex (hue), w1=black (S=*,L=0), w2=white (S=0,L=1)
    // The mapping is: L = w0*0.5 + w1*0 + w2*1  → w2 = L − w0*0.5 (approx)
    // Use a more direct method: express cursor in terms of apex/BL/BR vertices.
    // For the standard Hue-Saturation-Lightness triangle layout:
    //   w0 (apex) = saturation * (1 − |2L−1|) / 1   — not obvious from bary alone
    // Simpler: reconstruct via the affine map from (s, l) to barycentric.
    // At apex: L=0.5, S=1 → bary=(1,0,0)
    // At BL:   L=0,   S=* → bary=(0,1,0)
    // At BR:   L=1,   S=0 → bary=(0,0,1)
    // Affine fit: w0≈2*S*(0.5−|L−0.5|), but just lerp vertex positions:
    //   cursor_pos = w0*tv0 + w1*tv1 + w2*tv2
    // We derive w from S and L analytically:
    //   The chroma dimension along the apex-to-base axis is saturation.
    //   The white-black dimension is lightness.
    // A cleaner parameterisation:
    //   Along the base edge: t_lr = lightness  (0=black side, 1=white side)
    //   Along the apex-to-base axis: t_s  = saturation
    // base point = lerp(tv1, tv2, lightness)
    // cursor     = lerp(base_point, tv0, saturation)
    let tri_base_pt   = mix(tv1, tv2, u.lightness);
    let tri_cursor_local = mix(tri_base_pt, tv0, u.saturation);
    // Rotate back to screen space.
    let tri_cursor_screen = u.centre + rotate2d(tri_cursor_local, hue_angle_rad - 1.5707963267948966);

    let tri_cursor_d  = length(px - tri_cursor_screen);
    let tri_cursor_a  = 1.0 - smoothstep(u.cursor_radius - u.aa_width, u.cursor_radius + u.aa_width, tri_cursor_d);
    let tri_cursor_out= 1.0 - smoothstep(u.cursor_radius + 1.0 - u.aa_width, u.cursor_radius + 2.0 + u.aa_width, tri_cursor_d);

    // ── Composite ─────────────────────────────────────────────────────────────
    var out_col   = vec3<f32>(0.0);
    var out_alpha = 0.0;

    // Triangle layer (below the ring).
    if tri_mask > 0.0 {
        out_col   = mix(out_col,   tri_col, tri_mask);
        out_alpha = max(out_alpha, tri_mask);
    }

    // Hue ring on top of the triangle (they share the inner edge, ring wins).
    if ring_mask > 0.0 {
        out_col   = mix(out_col,   ring_col, ring_mask);
        out_alpha = max(out_alpha, ring_mask);
    }

    // Ring cursor: outline first (black), then fill (white dot).
    if ring_cursor_outline > 0.0 {
        let outline_col = vec3<f32>(0.0);
        out_col   = mix(out_col, outline_col, ring_cursor_outline * 0.8);
        out_alpha = max(out_alpha, ring_cursor_outline * 0.8);
    }
    if ring_cursor_a > 0.0 {
        let cursor_fill = vec3<f32>(1.0);
        out_col   = mix(out_col, cursor_fill, ring_cursor_a);
        out_alpha = max(out_alpha, ring_cursor_a);
    }

    // Triangle cursor: outline (black), fill (white).
    if tri_cursor_out > 0.0 {
        out_col   = mix(out_col, vec3<f32>(0.0), tri_cursor_out * 0.8);
        out_alpha = max(out_alpha, tri_cursor_out * 0.8 * f32(tri_mask > 0.5 || tri_cursor_a > 0.0));
    }
    if tri_cursor_a > 0.0 {
        out_col   = mix(out_col, vec3<f32>(1.0), tri_cursor_a);
        out_alpha = max(out_alpha, tri_cursor_a);
    }

    // Discard transparent pixels outside the wheel entirely.
    if out_alpha < 0.004 {
        discard;
    }

    return vec4<f32>(out_col, out_alpha);
}
