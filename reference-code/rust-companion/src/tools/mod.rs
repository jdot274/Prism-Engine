pub mod color_wheel;

use crate::ui::input::InputState;
use crate::ui::{ToolId, Rect};

/// Trait implemented by every interactive tool that renders into a card body.
///
/// # Lifecycle
/// 1. `update` is called once per frame with the current input state and the
///    pixel-space rectangle of the card body the tool occupies.
/// 2. `gpu_data` is called (also once per frame, after `update`) to extract
///    the data that will be uploaded to the GPU uniform buffer for rendering.
///
/// # Example
/// ```ignore
/// let mut tool = ColorWheelTool::new();
/// tool.update(dt, &input, card_rect);
/// let data = tool.gpu_data(card_rect);
/// ```
pub trait Tool {
    /// Returns the stable identifier that the UI system uses to route input
    /// and rendering to this tool.
    fn tool_id(&self) -> ToolId;

    /// Advance tool state by `dt` seconds, consuming relevant input events.
    ///
    /// `card_body_rect` is the pixel-space rectangle of the card body (not the
    /// title bar) in which the tool is rendered, used for hit-testing.
    fn update(&mut self, dt: f32, input: &InputState, card_body_rect: Rect);

    /// Produce a snapshot of GPU-ready data for this frame.
    ///
    /// `card_body_rect` must be the same value passed to the preceding
    /// `update` call so that coordinate systems stay consistent.
    fn gpu_data(&self, card_body_rect: Rect) -> ToolGpuData;
}

/// Tagged union of per-tool GPU data payloads.
///
/// Each variant corresponds to one tool and carries the uniform struct that
/// its dedicated pipeline expects.
pub enum ToolGpuData {
    ColorWheel(color_wheel::ColorWheelGpuData),
}
