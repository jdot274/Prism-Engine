pub mod card;
pub mod input;
pub mod launcher;

// ---------------------------------------------------------------------------
// Layout constants
// ---------------------------------------------------------------------------

pub const LAUNCHER_W: f32    = 72.0;
pub const ICON_SIZE: f32     = 48.0;
pub const ICON_PADDING: f32  = 12.0;
pub const CARD_W: f32        = 480.0;
pub const CARD_H: f32        = 480.0;
pub const CARD_HEADER_H: f32 = 44.0;
pub const CARD_CORNER_R: f32 = 12.0;
pub const ANIMATION_SPEED: f32 = 12.0;

// ---------------------------------------------------------------------------
// Palette
// ---------------------------------------------------------------------------

pub const VOID:         [f32; 4] = [0.031, 0.039, 0.055, 1.0];
pub const OBSIDIAN:     [f32; 4] = [0.051, 0.067, 0.090, 1.0];
pub const PRISM_CYAN:   [f32; 4] = [0.0,   0.961, 1.0,   1.0];
pub const PRISM_VIOLET: [f32; 4] = [0.545, 0.361, 0.965, 1.0];
pub const PRISM_LIME:   [f32; 4] = [0.659, 1.0,   0.0,   1.0];
pub const PRISM_AMBER:  [f32; 4] = [1.0,   0.733, 0.0,   1.0];
pub const TEXT:         [f32; 4] = [0.929, 0.949, 1.0,   1.0];
pub const TEXT_MUTED:   [f32; 4] = [0.478, 0.541, 0.659, 1.0];

// ---------------------------------------------------------------------------
// ToolId
// ---------------------------------------------------------------------------

#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub enum ToolId {
    ColorWheel,
    GradientDesigner,
    LightMixer,
    PbrValidator,
    ScatterBrush,
    CurveBalancer,
    TickBudget,
    ChannelPacker,
}

impl ToolId {
    /// All tools in display order.
    pub const ALL: [ToolId; 8] = [
        ToolId::ColorWheel,
        ToolId::GradientDesigner,
        ToolId::LightMixer,
        ToolId::PbrValidator,
        ToolId::ScatterBrush,
        ToolId::CurveBalancer,
        ToolId::TickBudget,
        ToolId::ChannelPacker,
    ];

    /// Human-readable label (localization key placeholder).
    pub fn label(self) -> &'static str {
        match self {
            ToolId::ColorWheel       => "Color Wheel",
            ToolId::GradientDesigner => "Gradient",
            ToolId::LightMixer       => "Light Mixer",
            ToolId::PbrValidator     => "PBR Validator",
            ToolId::ScatterBrush     => "Scatter Brush",
            ToolId::CurveBalancer    => "Curve Balancer",
            ToolId::TickBudget       => "Tick Budget",
            ToolId::ChannelPacker    => "Channel Packer",
        }
    }

    /// Unicode glyph shown in the launcher icon.
    pub fn glyph(self) -> &'static str {
        match self {
            ToolId::ColorWheel       => "\u{2B24}",  // ⬤
            ToolId::GradientDesigner => "\u{25A6}",  // ▦
            ToolId::LightMixer       => "\u{2726}",  // ✦
            ToolId::PbrValidator     => "\u{2713}",  // ✓
            ToolId::ScatterBrush     => "\u{2058}",  // ⁘
            ToolId::CurveBalancer    => "\u{223F}",  // ∿
            ToolId::TickBudget       => "\u{2590}",  // ▐
            ToolId::ChannelPacker    => "\u{29C9}",  // ⧉
        }
    }

    /// Accent colour from the palette.
    pub fn accent(self) -> [f32; 4] {
        match self {
            ToolId::ColorWheel       => PRISM_CYAN,
            ToolId::GradientDesigner => PRISM_VIOLET,
            ToolId::LightMixer       => PRISM_AMBER,
            ToolId::PbrValidator     => PRISM_LIME,
            ToolId::ScatterBrush     => PRISM_CYAN,
            ToolId::CurveBalancer    => PRISM_VIOLET,
            ToolId::TickBudget       => PRISM_AMBER,
            ToolId::ChannelPacker    => PRISM_LIME,
        }
    }

    /// Zero-based display index.
    pub fn index(self) -> usize {
        match self {
            ToolId::ColorWheel       => 0,
            ToolId::GradientDesigner => 1,
            ToolId::LightMixer       => 2,
            ToolId::PbrValidator     => 3,
            ToolId::ScatterBrush     => 4,
            ToolId::CurveBalancer    => 5,
            ToolId::TickBudget       => 6,
            ToolId::ChannelPacker    => 7,
        }
    }
}

// ---------------------------------------------------------------------------
// Rect
// ---------------------------------------------------------------------------

#[derive(Debug, Clone, Copy)]
pub struct Rect {
    pub x: f32,
    pub y: f32,
    pub w: f32,
    pub h: f32,
}

impl Rect {
    #[inline]
    pub fn new(x: f32, y: f32, w: f32, h: f32) -> Self {
        Self { x, y, w, h }
    }

    #[inline]
    pub fn contains(&self, pt: glam::Vec2) -> bool {
        pt.x >= self.x
            && pt.x < self.x + self.w
            && pt.y >= self.y
            && pt.y < self.y + self.h
    }

    #[inline]
    pub fn center(&self) -> glam::Vec2 {
        glam::Vec2::new(self.x + self.w * 0.5, self.y + self.h * 0.5)
    }

    #[inline]
    pub fn expand(&self, amount: f32) -> Rect {
        Rect {
            x: self.x - amount,
            y: self.y - amount,
            w: self.w + amount * 2.0,
            h: self.h + amount * 2.0,
        }
    }
}
