use crate::ui::input::InputState;
use crate::ui::{Rect, ToolId};
use super::{Tool, ToolGpuData};

// ---------------------------------------------------------------------------
// Drag-state enum
// ---------------------------------------------------------------------------

/// Tracks which region of the colour wheel the user is currently dragging.
#[derive(Default, PartialEq, Clone, Copy)]
enum WheelRegion {
    /// No drag in progress.
    #[default]
    None,
    /// The user is dragging the outer hue ring.
    HueRing,
    /// The user is dragging inside the inner SL triangle.
    Triangle,
}

// ---------------------------------------------------------------------------
// GPU data payload
// ---------------------------------------------------------------------------

/// Uniform data uploaded to the GPU each frame for colour-wheel rendering.
///
/// All coordinates are in pixel-space matching the surface resolution.
/// `_pad` exists solely to satisfy WGSL's 16-byte struct-alignment rule.
#[repr(C)]
#[derive(Copy, Clone, bytemuck::Pod, bytemuck::Zeroable)]
pub struct ColorWheelGpuData {
    /// Pixel-space centre of the wheel.
    pub center: [f32; 2],
    /// Radius of the outer edge of the hue ring (pixels).
    pub outer_r: f32,
    /// Radius of the inner edge of the hue ring (pixels).  Also the
    /// circumradius of the SL triangle.
    pub inner_r: f32,
    /// Currently selected hue in [0, 1).
    pub selected_hue: f32,
    /// Currently selected saturation in [0, 1].
    pub selected_sat: f32,
    /// Currently selected luminance in [0, 1].
    pub selected_lum: f32,
    /// Padding — do not use.
    pub _pad: f32,
}

// ---------------------------------------------------------------------------
// Tool struct
// ---------------------------------------------------------------------------

/// Interactive HSL colour-wheel tool.
///
/// The wheel is split into two interactive regions:
/// - **Hue ring** — the annular region between `inner_r` and `outer_r`.
///   Dragging sets the hue from the polar angle.
/// - **SL triangle** — an equilateral triangle inscribed in the inner circle.
///   Dragging maps barycentric coordinates to (saturation, luminance).
///
/// After mouse release the currently selected colour is latched into
/// `applied_color` in linear sRGB.
///
/// # Example
/// ```ignore
/// let mut wheel = ColorWheelTool::new();
/// // Each frame:
/// wheel.update(dt, &input, card_rect);
/// let gpu = wheel.gpu_data(card_rect);
/// ```
pub struct ColorWheelTool {
    /// Current hue in [0, 1).
    pub hue: f32,
    /// Current saturation in [0, 1].
    pub saturation: f32,
    /// Current luminance in [0, 1].
    pub luminance: f32,
    /// The colour that was confirmed on the last mouse-up, in linear RGBA.
    pub applied_color: [f32; 4],

    dragging: WheelRegion,
    was_mouse_down: bool,
}

impl ColorWheelTool {
    /// Construct a colour-wheel tool with a pleasant default cyan-ish colour
    /// (hue = 0.58, sat = 0.80, lum = 0.50).
    pub fn new() -> Self {
        let hue = 0.58_f32;
        let sat = 0.80_f32;
        let lum = 0.50_f32;
        let rgb = Self::hsl_to_rgb(hue, sat, lum);
        Self {
            hue,
            saturation: sat,
            luminance: lum,
            applied_color: [rgb[0], rgb[1], rgb[2], 1.0],
            dragging: WheelRegion::None,
            was_mouse_down: false,
        }
    }

    // -----------------------------------------------------------------------
    // Public helpers
    // -----------------------------------------------------------------------

    /// Return the current selection as a linear-sRGB RGBA quad.
    pub fn selected_rgba(&self) -> [f32; 4] {
        let rgb = Self::hsl_to_rgb(self.hue, self.saturation, self.luminance);
        [rgb[0], rgb[1], rgb[2], 1.0]
    }

    /// Produce GPU uniform data for this frame using `card_body_rect` to
    /// derive the wheel centre and radii.
    pub fn gpu_data(&self, card_body_rect: Rect) -> ColorWheelGpuData {
        let (center, outer_r, inner_r) = Self::geometry(card_body_rect);
        ColorWheelGpuData {
            center,
            outer_r,
            inner_r,
            selected_hue: self.hue,
            selected_sat: self.saturation,
            selected_lum: self.luminance,
            _pad: 0.0,
        }
    }

    // -----------------------------------------------------------------------
    // Internal geometry helpers
    // -----------------------------------------------------------------------

    /// Compute (center, outer_r, inner_r) from the card body rect.
    fn geometry(rect: Rect) -> ([f32; 2], f32, f32) {
        let cx = rect.x + rect.w * 0.5;
        let cy = rect.y + rect.h * 0.5;
        let outer_r = rect.w.min(rect.h) * 0.45;
        let inner_r = outer_r * 0.78;
        ([cx, cy], outer_r, inner_r)
    }

    /// Test whether `pos` falls inside the hue ring (annulus).
    fn hit_ring(pos: [f32; 2], center: [f32; 2], outer_r: f32, inner_r: f32) -> bool {
        let dx = pos[0] - center[0];
        let dy = pos[1] - center[1];
        let d2 = dx * dx + dy * dy;
        d2 >= inner_r * inner_r && d2 <= outer_r * outer_r
    }

    /// Test whether `pos` falls inside the SL equilateral triangle that is
    /// inscribed in a circle of radius `inner_r` around `center`, with the
    /// top vertex pointing in the direction of the current hue angle.
    ///
    /// Returns `Some((s, l))` clamped to [0,1]² if inside, else `None`.
    fn hit_triangle(
        pos: [f32; 2],
        center: [f32; 2],
        inner_r: f32,
        hue_angle: f32,
    ) -> Option<(f32, f32)> {
        // Three vertices of an equilateral triangle rotated so that vertex 0
        // is at the hue angle.  The triangle is inscribed in the inner circle.
        let v = |i: f32| -> [f32; 2] {
            let angle = hue_angle + i * std::f32::consts::TAU / 3.0;
            [
                center[0] + inner_r * angle.cos(),
                center[1] + inner_r * angle.sin(),
            ]
        };
        let a = v(0.0); // hue corner  → full saturation, mid luminance
        let b = v(1.0); // white corner → zero saturation, full luminance
        let c = v(2.0); // black corner → zero saturation, zero luminance

        // Barycentric coordinates of `pos` w.r.t. triangle ABC.
        let denom = (b[1] - c[1]) * (a[0] - c[0]) + (c[0] - b[0]) * (a[1] - c[1]);
        if denom.abs() < 1e-6 {
            return None;
        }
        let wa = ((b[1] - c[1]) * (pos[0] - c[0]) + (c[0] - b[0]) * (pos[1] - c[1])) / denom;
        let wb = ((c[1] - a[1]) * (pos[0] - c[0]) + (a[0] - c[0]) * (pos[1] - c[1])) / denom;
        let wc = 1.0 - wa - wb;

        // Only report a hit when all weights are non-negative (inside triangle).
        if wa >= 0.0 && wb >= 0.0 && wc >= 0.0 {
            // Interpret barycentric weights:
            //   vertex a → (sat=1, lum=0.5)  — pure hue
            //   vertex b → (sat=0, lum=1.0)  — white
            //   vertex c → (sat=0, lum=0.0)  — black
            let sat = wa.clamp(0.0, 1.0);
            let lum = (wb * 1.0 + wc * 0.0 + wa * 0.5).clamp(0.0, 1.0);
            Some((sat, lum))
        } else {
            None
        }
    }

    // -----------------------------------------------------------------------
    // Colour math
    // -----------------------------------------------------------------------

    /// Standard HSL → linear-sRGB conversion.
    ///
    /// All inputs in [0, 1].  Output channels in [0, 1].
    pub fn hsl_to_rgb(h: f32, s: f32, l: f32) -> [f32; 3] {
        if s == 0.0 {
            return [l, l, l];
        }
        let q = if l < 0.5 {
            l * (1.0 + s)
        } else {
            l + s - l * s
        };
        let p = 2.0 * l - q;

        let hue_to_channel = |mut t: f32| -> f32 {
            if t < 0.0 { t += 1.0; }
            if t > 1.0 { t -= 1.0; }
            if t < 1.0 / 6.0 {
                p + (q - p) * 6.0 * t
            } else if t < 1.0 / 2.0 {
                q
            } else if t < 2.0 / 3.0 {
                p + (q - p) * (2.0 / 3.0 - t) * 6.0
            } else {
                p
            }
        };

        [
            hue_to_channel(h + 1.0 / 3.0),
            hue_to_channel(h),
            hue_to_channel(h - 1.0 / 3.0),
        ]
    }
}

impl Default for ColorWheelTool {
    fn default() -> Self {
        Self::new()
    }
}

// ---------------------------------------------------------------------------
// Tool trait impl
// ---------------------------------------------------------------------------

impl Tool for ColorWheelTool {
    fn tool_id(&self) -> ToolId {
        ToolId::ColorWheel
    }

    /// Advance the colour-wheel state for one frame.
    ///
    /// Hit-testing uses pixel-space coordinates from `input` and the wheel
    /// geometry derived from `card_body_rect`.
    fn update(&mut self, _dt: f32, input: &InputState, card_body_rect: Rect) {
        let (center, outer_r, inner_r) = Self::geometry(card_body_rect);
        let mouse = input.mouse_pos;
        let is_down = input.mouse_down;

        // --- Press: determine which region was clicked ---------------------
        if is_down && !self.was_mouse_down {
            if Self::hit_ring(mouse, center, outer_r, inner_r) {
                self.dragging = WheelRegion::HueRing;
            } else {
                // Check triangle hit using the current hue angle.
                let hue_angle = self.hue * std::f32::consts::TAU;
                if Self::hit_triangle(mouse, center, inner_r, hue_angle).is_some() {
                    self.dragging = WheelRegion::Triangle;
                }
            }
        }

        // --- Drag: update HSL values ---------------------------------------
        if is_down {
            match self.dragging {
                WheelRegion::HueRing => {
                    let dx = mouse[0] - center[0];
                    let dy = mouse[1] - center[1];
                    // atan2 returns [-π, π]; normalise to [0, 1).
                    let angle = dy.atan2(dx);
                    self.hue = (angle / std::f32::consts::TAU).rem_euclid(1.0);
                }
                WheelRegion::Triangle => {
                    let hue_angle = self.hue * std::f32::consts::TAU;
                    // Clamp to the nearest valid SL when dragged outside the
                    // triangle by projecting the cursor toward the centroid.
                    let (sat, lum) = Self::hit_triangle(mouse, center, inner_r, hue_angle)
                        .unwrap_or_else(|| {
                            // Project toward centroid until we find a valid point.
                            let steps = 16_u32;
                            let mut best = (self.saturation, self.luminance);
                            for i in 1..=steps {
                                let t = i as f32 / steps as f32;
                                let p = [
                                    mouse[0] + (center[0] - mouse[0]) * t,
                                    mouse[1] + (center[1] - mouse[1]) * t,
                                ];
                                if let Some(sl) =
                                    Self::hit_triangle(p, center, inner_r, hue_angle)
                                {
                                    best = sl;
                                    break;
                                }
                            }
                            best
                        });
                    self.saturation = sat;
                    self.luminance = lum;
                }
                WheelRegion::None => {}
            }
        }

        // --- Release: latch applied_color ----------------------------------
        if !is_down && self.was_mouse_down && self.dragging != WheelRegion::None {
            self.applied_color = self.selected_rgba();
            self.dragging = WheelRegion::None;
        }

        self.was_mouse_down = is_down;
    }

    fn gpu_data(&self, card_body_rect: Rect) -> ToolGpuData {
        ToolGpuData::ColorWheel(self.gpu_data(card_body_rect))
    }
}
