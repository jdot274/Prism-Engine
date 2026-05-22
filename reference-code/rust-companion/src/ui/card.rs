use glam::Vec2;

use crate::ui::{
    Rect, ToolId,
    LAUNCHER_W, CARD_W, CARD_H, CARD_HEADER_H, ANIMATION_SPEED,
};

#[derive(Debug, Clone)]
pub struct DragState {
    pub start_mouse:    Vec2,
    pub start_card_pos: Vec2,
}

#[derive(Debug)]
pub struct ToolCard {
    pub tool:    ToolId,
    pub pos:     Vec2,
    pub is_open: bool,
    pub open_t:  f32,
    pub hover_t: f32,
    pub z_order: u32,
    pub drag:    Option<DragState>,
}

impl ToolCard {
    fn new(tool: ToolId, pos: Vec2, z_order: u32) -> Self {
        Self {
            tool,
            pos,
            is_open: true,
            open_t: 0.0,
            hover_t: 0.0,
            z_order,
            drag: None,
        }
    }

    pub fn full_rect(&self) -> Rect {
        Rect::new(self.pos.x, self.pos.y, CARD_W, CARD_H)
    }

    pub fn header_rect(&self) -> Rect {
        Rect::new(self.pos.x, self.pos.y, CARD_W, CARD_HEADER_H)
    }

    pub fn body_rect(&self) -> Rect {
        Rect::new(self.pos.x, self.pos.y + CARD_HEADER_H, CARD_W, CARD_H - CARD_HEADER_H)
    }
}

#[derive(Debug, Default)]
pub struct CardManager {
    pub cards: Vec<ToolCard>,
    cursor: Vec2,
}

impl CardManager {
    pub fn new() -> Self {
        Self { cards: Vec::new(), cursor: Vec2::ZERO }
    }

    pub fn set_cursor(&mut self, pos: Vec2) {
        self.cursor = pos;
    }

    fn max_z(&self) -> u32 {
        self.cards.iter().map(|c| c.z_order).max().unwrap_or(0)
    }

    fn clamp_pos(pos: Vec2, screen: Vec2) -> Vec2 {
        let x = pos.x.clamp(LAUNCHER_W, screen.x - CARD_W);
        let y = pos.y.clamp(0.0, screen.y - CARD_HEADER_H);
        Vec2::new(x, y)
    }

    /// Open a card. If already open, bring to front. If closed, reopen at last pos.
    /// New cards spawn at `near_pos` (unclamped — first update will clamp if dragged).
    pub fn open_card(&mut self, tool: ToolId, near_pos: Vec2) {
        let new_z = self.max_z() + 1;
        if let Some(card) = self.cards.iter_mut().find(|c| c.tool == tool) {
            card.is_open = true;
            card.z_order = new_z;
            return;
        }
        self.cards.push(ToolCard::new(tool, near_pos, new_z));
    }

    pub fn close_card(&mut self, tool: ToolId) {
        if let Some(card) = self.cards.iter_mut().find(|c| c.tool == tool) {
            card.is_open = false;
        }
    }

    pub fn is_open(&self, tool: ToolId) -> bool {
        self.cards.iter().any(|c| c.tool == tool && c.is_open)
    }

    pub fn begin_drag(&mut self, cursor: Vec2) -> Option<ToolId> {
        let target = self
            .cards
            .iter()
            .filter(|c| c.is_open && c.header_rect().contains(cursor))
            .max_by_key(|c| c.z_order)
            .map(|c| c.tool);

        if let Some(tool) = target {
            let new_z = self.max_z() + 1;
            if let Some(card) = self.cards.iter_mut().find(|c| c.tool == tool) {
                card.z_order = new_z;
                card.drag = Some(DragState {
                    start_mouse:    cursor,
                    start_card_pos: card.pos,
                });
            }
        }
        target
    }

    pub fn update_drag(&mut self, cursor: Vec2, screen: Vec2) {
        for card in &mut self.cards {
            if let Some(ref drag) = card.drag {
                let delta   = cursor - drag.start_mouse;
                let new_pos = drag.start_card_pos + delta;
                card.pos    = Self::clamp_pos(new_pos, screen);
            }
        }
    }

    pub fn end_drag(&mut self) {
        for card in &mut self.cards {
            card.drag = None;
        }
    }

    /// Advance animations; prune fully-closed cards.
    pub fn update(&mut self, dt: f32, screen: Vec2) {
        let cursor = self.cursor;
        for card in &mut self.cards {
            let open_target = if card.is_open { 1.0_f32 } else { 0.0_f32 };
            card.open_t += (open_target - card.open_t) * ANIMATION_SPEED * dt;
            card.open_t  = card.open_t.clamp(0.0, 1.0);

            let hover_target = if card.full_rect().contains(cursor) { 1.0_f32 } else { 0.0_f32 };
            card.hover_t += (hover_target - card.hover_t) * ANIMATION_SPEED * dt;
            card.hover_t  = card.hover_t.clamp(0.0, 1.0);

            // Clamp position in case window was resized.
            if card.drag.is_none() {
                card.pos = Self::clamp_pos(card.pos, screen);
            }
        }
        self.cards.retain(|c| c.is_open || c.open_t >= 0.001);
    }

    /// Indices into `self.cards` sorted ascending by z_order (back to front).
    pub fn draw_order(&self) -> Vec<usize> {
        let mut indices: Vec<usize> = (0..self.cards.len()).collect();
        indices.sort_by_key(|&i| self.cards[i].z_order);
        indices
    }
}
