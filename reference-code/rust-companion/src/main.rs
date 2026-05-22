use std::sync::Arc;
use winit::application::ApplicationHandler;
use winit::dpi::PhysicalSize;
use winit::event::WindowEvent;
use winit::event_loop::{ActiveEventLoop, ControlFlow, EventLoop};
use winit::window::{Window, WindowAttributes, WindowId};

mod gpu;
mod renderer;
mod pipelines;
mod tools;
mod ui;

use gpu::GpuState;
use renderer::Renderer;
use ui::{card::CardManager, launcher::LauncherState};
use ui::input::{InputState, process_event};

const WINDOW_TITLE: &str = "Prism — The studio in a window";
const INITIAL_W: u32 = 1440;
const INITIAL_H: u32 = 900;

struct PrismApp {
    window: Option<Arc<Window>>,
    gpu: Option<GpuState>,
    renderer: Option<Renderer>,
    launcher: LauncherState,
    cards: CardManager,
    input: InputState,
    last_frame: std::time::Instant,
}

impl Default for PrismApp {
    fn default() -> Self {
        Self {
            window: None,
            gpu: None,
            renderer: None,
            launcher: LauncherState::new(),
            cards: CardManager::new(),
            input: InputState::default(),
            last_frame: std::time::Instant::now(),
        }
    }
}

impl ApplicationHandler for PrismApp {
    fn resumed(&mut self, event_loop: &ActiveEventLoop) {
        let window = Arc::new(
            event_loop
                .create_window(
                    WindowAttributes::default()
                        .with_title(WINDOW_TITLE)
                        .with_inner_size(PhysicalSize::new(INITIAL_W, INITIAL_H))
                        .with_min_inner_size(PhysicalSize::new(800u32, 600u32)),
                )
                .expect("failed to create window"),
        );

        let gpu = GpuState::new_sync(window.clone());
        let renderer = Renderer::new(&gpu);

        self.gpu = Some(gpu);
        self.renderer = Some(renderer);
        self.window = Some(window);
    }

    fn window_event(
        &mut self,
        event_loop: &ActiveEventLoop,
        _window_id: WindowId,
        event: WindowEvent,
    ) {
        let screen_size = self
            .gpu
            .as_ref()
            .map(|g| glam::Vec2::new(g.size.width as f32, g.size.height as f32))
            .unwrap_or(glam::Vec2::new(INITIAL_W as f32, INITIAL_H as f32));

        // Route input
        let result = process_event(
            &event,
            &mut self.input,
            &mut self.launcher,
            &mut self.cards,
            screen_size,
        );

        use ui::input::EventResult;
        match result {
            EventResult::OpenCard(tool_id) => {
                let spawn_pos = glam::Vec2::new(
                    ui::LAUNCHER_W + 24.0,
                    24.0 + tool_id.index() as f32 * 32.0,
                );
                self.cards.open_card(tool_id, spawn_pos);
            }
            EventResult::CloseCard(tool_id) => {
                self.cards.close_card(tool_id);
            }
            _ => {}
        }

        match event {
            WindowEvent::CloseRequested => event_loop.exit(),

            WindowEvent::Resized(size) => {
                if let (Some(gpu), Some(renderer)) =
                    (self.gpu.as_mut(), self.renderer.as_mut())
                {
                    gpu.resize(size);
                    renderer.resize(gpu);
                }
                if let Some(w) = &self.window {
                    w.request_redraw();
                }
            }

            WindowEvent::RedrawRequested => {
                let now = std::time::Instant::now();
                let dt = now.duration_since(self.last_frame).as_secs_f32().min(0.05);
                self.last_frame = now;

                let screen = screen_size;
                self.launcher.update(dt);
                self.cards.update(dt, screen);

                if let (Some(gpu), Some(renderer)) =
                    (self.gpu.as_ref(), self.renderer.as_mut())
                {
                    renderer.draw_frame(gpu, &self.launcher, &self.cards, dt);
                }
            }
            _ => {}
        }
    }

    fn about_to_wait(&mut self, _event_loop: &ActiveEventLoop) {
        if let Some(w) = &self.window {
            w.request_redraw();
        }
    }
}

fn main() {
    env_logger::Builder::from_env(env_logger::Env::default().default_filter_or("warn"))
        .init();

    let event_loop = EventLoop::new().expect("create event loop");
    event_loop.set_control_flow(ControlFlow::Poll);

    let mut app = PrismApp::default();
    event_loop.run_app(&mut app).expect("event loop failed");
}
