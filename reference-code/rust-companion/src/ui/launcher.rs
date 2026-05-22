use glam::Vec2;

use crate::ui::{
    Rect, ToolId,
    LAUNCHER_W, ICON_SIZE, ICON_PADDING, ANIMATION_SPEED,
};

fn icon_rect_for_index(index: usize) -> Rect {
    let x = (LAUNCHER_W - ICON_SIZE) * 0.5;
    let y = 16.0 + index as f32 * (ICON_SIZE + ICON_PADDING);
    Rect::new(x, y, ICON_SIZE, ICON_SIZE)
}

#[derive(Debug, Clone)]
pub struct LauncherIconData {
    pub tool:    ToolId,
    pub rect:    Rect,
    pub hover_t: f32,
    pub active:  bool,
}

impl LauncherIconData {
    fn new(tool: ToolId) -> Self {
        Self {
            tool,
            rect: icon_rect_for_index(tool.index()),
            hover_t: 0.0,
            active: false,
        }
    }
}

#[derive(Debug)]
pub struct LauncherState {
    pub icons: [LauncherIconData; 8],
    cursor: Vec2,
}

impl LauncherState {
    pub fn new() -> Self {
        Self {
            icons: [
                LauncherIconData::new(ToolId::ColorWheel),
                LauncherIconData::new(ToolId::GradientDesigner),
                LauncherIconData::new(ToolId::LightMixer),
                LauncherIconData::new(ToolId::PbrValidator),
                LauncherIconData::new(ToolId::ScatterBrush),
                LauncherIconData::new(ToolId::CurveBalancer),
                LauncherIconData::new(ToolId::TickBudget),
                LauncherIconData::new(ToolId::ChannelPacker),
            ],
            cursor: Vec2::ZERO,
        }
    }

    pub fn set_cursor(&mut self, pos: Vec2) {
        self.cursor = pos;
    }

    pub fn hit_test(&self, cursor: Vec2) -> Option<ToolId> {
        for icon in &self.icons {
            if icon.rect.contains(cursor) {
                return Some(icon.tool);
            }
        }
        None
    }

    /// Advance hover animations. Called once per frame with frame delta.
    pub fn update(&mut self, dt: f32) {
        for icon in &mut self.icons {
            let target = if icon.rect.contains(self.cursor) { 1.0_f32 } else { 0.0_f32 };
            icon.hover_t += (target - icon.hover_t) * ANIMATION_SPEED * dt;
            icon.hover_t = icon.hover_t.clamp(0.0, 1.0);
        }
    }

    pub fn set_active(&mut self, tool: ToolId, active: bool) {
        if let Some(icon) = self.icons.iter_mut().find(|i| i.tool == tool) {
            icon.active = active;
        }
    }
}

impl Default for LauncherState {
    fn default() -> Self {
        Self::new()
    }
}
