use glam::Vec2;
use winit::{
    event::{ElementState, MouseButton, WindowEvent},
    keyboard::ModifiersState,
};

use crate::ui::{ToolId, launcher::LauncherState, card::CardManager};

#[derive(Debug, Default)]
pub struct InputState {
    pub cursor: Vec2,
    /// Alias of cursor as [f32; 2] — consumed by tools (e.g. ColorWheelTool).
    pub mouse_pos: [f32; 2],
    /// True while the left mouse button is held — consumed by tools.
    pub mouse_down: bool,
    pub mouse_left: bool,
    pub mouse_right: bool,
    pub modifiers: ModifiersState,
}

#[derive(Debug, Clone, PartialEq)]
pub enum EventResult {
    OpenCard(ToolId),
    CloseCard(ToolId),
    Consumed,
    Passthrough,
}

/// Route a winit WindowEvent to input state, launcher, and card system.
/// Returns an `EventResult` indicating any high-level action the caller must act on.
pub fn process_event(
    event: &WindowEvent,
    input: &mut InputState,
    launcher: &mut LauncherState,
    cards: &mut CardManager,
    screen_size: Vec2,
) -> EventResult {
    match event {
        WindowEvent::CursorMoved { position, .. } => {
            let pos = Vec2::new(position.x as f32, position.y as f32);
            input.cursor = pos;
            input.mouse_pos = pos.into();
            launcher.set_cursor(pos);
            cards.set_cursor(pos);
            cards.update_drag(pos, screen_size);
            EventResult::Consumed
        }

        WindowEvent::MouseInput {
            state: btn_state,
            button: MouseButton::Left,
            ..
        } => {
            let pressed = *btn_state == ElementState::Pressed;
            input.mouse_left = pressed;
            input.mouse_down = pressed;

            if pressed {
                let pos = input.cursor;

                // Launcher click: toggle card open/close.
                if let Some(tool_id) = launcher.hit_test(pos) {
                    if cards.is_open(tool_id) {
                        launcher.set_active(tool_id, false);
                        return EventResult::CloseCard(tool_id);
                    } else {
                        launcher.set_active(tool_id, true);
                        return EventResult::OpenCard(tool_id);
                    }
                }

                // Card header drag start.
                cards.begin_drag(pos);
                EventResult::Consumed
            } else {
                cards.end_drag();
                EventResult::Consumed
            }
        }

        WindowEvent::MouseInput {
            state: btn_state,
            button: MouseButton::Right,
            ..
        } => {
            input.mouse_right = *btn_state == ElementState::Pressed;
            EventResult::Passthrough
        }

        WindowEvent::ModifiersChanged(mods) => {
            input.modifiers = mods.state();
            EventResult::Passthrough
        }

        _ => EventResult::Passthrough,
    }
}
