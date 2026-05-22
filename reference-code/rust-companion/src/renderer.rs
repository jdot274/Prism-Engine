use crate::gpu::GpuState;
use crate::pipelines::{
    background::{BackgroundPipeline, CanvasUniforms},
    card::{CardPipeline, CardUniforms},
    color_wheel::{ColorWheelPipeline, WheelUniforms},
    bloom::BloomPipeline,
};
use crate::ui::card::CardManager;
use crate::ui::launcher::LauncherState;
use crate::ui::{ToolId, VOID};

pub struct Renderer {
    background: BackgroundPipeline,
    card: CardPipeline,
    color_wheel: ColorWheelPipeline,
    bloom: BloomPipeline,
    // Intermediate HDR target for bloom post-process
    hdr_texture: wgpu::Texture,
    hdr_view: wgpu::TextureView,
    time: f32,
}

impl Renderer {
    pub fn new(gpu: &GpuState) -> Self {
        let fmt = gpu.surface_format;
        let (w, h) = (gpu.size.width.max(1), gpu.size.height.max(1));

        let hdr_texture = Self::make_hdr_texture(&gpu.device, fmt, w, h);
        let hdr_view = hdr_texture.create_view(&Default::default());

        Self {
            background: BackgroundPipeline::new(&gpu.device, fmt),
            card: CardPipeline::new(&gpu.device, fmt),
            color_wheel: ColorWheelPipeline::new(&gpu.device, fmt),
            bloom: BloomPipeline::new(&gpu.device, fmt, w, h),
            hdr_texture,
            hdr_view,
            time: 0.0,
        }
    }

    pub fn resize(&mut self, gpu: &GpuState) {
        let (w, h) = (gpu.size.width.max(1), gpu.size.height.max(1));
        self.hdr_texture = Self::make_hdr_texture(&gpu.device, gpu.surface_format, w, h);
        self.hdr_view = self.hdr_texture.create_view(&Default::default());
        self.bloom.resize(&gpu.device, w, h);
    }

    pub fn draw_frame(
        &mut self,
        gpu: &GpuState,
        _launcher: &LauncherState,
        cards: &CardManager,
        dt: f32,
    ) {
        self.time += dt;

        let output = match gpu.current_texture() {
            Ok(t) => t,
            Err(wgpu::SurfaceError::Lost | wgpu::SurfaceError::Outdated) => return,
            Err(e) => { log::error!("surface error: {e}"); return; }
        };
        let output_view = output.texture.create_view(&Default::default());

        let res = [gpu.size.width as f32, gpu.size.height as f32];

        // --- Pass 1: scene → HDR target ----------------------------------
        let mut encoder = gpu.device.create_command_encoder(
            &wgpu::CommandEncoderDescriptor { label: Some("prism-scene") }
        );

        // Background
        self.background.update_uniforms(&gpu.queue, CanvasUniforms {
            resolution: res,
            time: self.time,
            _pad: 0.0,
        });
        {
            let mut rpass = encoder.begin_render_pass(&wgpu::RenderPassDescriptor {
                label: Some("background"),
                color_attachments: &[Some(wgpu::RenderPassColorAttachment {
                    view: &self.hdr_view,
                    resolve_target: None,
                    ops: wgpu::Operations {
                        load: wgpu::LoadOp::Clear(wgpu::Color {
                            r: VOID[0] as f64,
                            g: VOID[1] as f64,
                            b: VOID[2] as f64,
                            a: 1.0,
                        }),
                        store: wgpu::StoreOp::Store,
                    },
                })],
                depth_stencil_attachment: None,
                timestamp_writes: None,
                occlusion_query_set: None,
            });
            self.background.draw(&mut rpass);
        }

        // Cards (back to front)
        let draw_order = cards.draw_order();
        for &idx in &draw_order {
            let card = &cards.cards[idx];
            if card.open_t < 0.001 { continue; }

            let accent = card.tool.accent();

            // Card chrome
            self.card.update_uniforms(&gpu.queue, CardUniforms {
                pos: card.pos.into(),
                size: [crate::ui::CARD_W, crate::ui::CARD_H],
                resolution: res,
                accent_color: accent,
                hover_t: card.open_t,
                _pad: [0.0; 3],
            });
            {
                let mut rpass = encoder.begin_render_pass(&wgpu::RenderPassDescriptor {
                    label: Some("card"),
                    color_attachments: &[Some(wgpu::RenderPassColorAttachment {
                        view: &self.hdr_view,
                        resolve_target: None,
                        ops: wgpu::Operations {
                            load: wgpu::LoadOp::Load,
                            store: wgpu::StoreOp::Store,
                        },
                    })],
                    depth_stencil_attachment: None,
                    timestamp_writes: None,
                    occlusion_query_set: None,
                });
                self.card.draw(&mut rpass);
            }

            // Tool-specific content
            if card.tool == ToolId::ColorWheel {
                let body = card.body_rect();
                let cx = body.x + body.w * 0.5;
                let cy = body.y + body.h * 0.5;
                let outer_r = body.w.min(body.h) * 0.45;
                let inner_r = outer_r * 0.78;

                self.color_wheel.update_uniforms(&gpu.queue, WheelUniforms {
                    center: [cx, cy],
                    outer_r,
                    inner_r,
                    selected_hue: 0.58,
                    selected_sat: 0.8,
                    selected_lum: 0.5,
                    _pad: 0.0,
                });
                {
                    let mut rpass = encoder.begin_render_pass(&wgpu::RenderPassDescriptor {
                        label: Some("color-wheel"),
                        color_attachments: &[Some(wgpu::RenderPassColorAttachment {
                            view: &self.hdr_view,
                            resolve_target: None,
                            ops: wgpu::Operations {
                                load: wgpu::LoadOp::Load,
                                store: wgpu::StoreOp::Store,
                            },
                        })],
                        depth_stencil_attachment: None,
                        timestamp_writes: None,
                        occlusion_query_set: None,
                    });
                    self.color_wheel.draw(&mut rpass);
                }
            }
        }

        gpu.queue.submit(std::iter::once(encoder.finish()));

        // --- Pass 2: bloom post-process → swapchain ----------------------
        self.bloom.apply(&gpu.device, &gpu.queue, &self.hdr_view, &output_view);

        output.present();
    }

    fn make_hdr_texture(
        device: &wgpu::Device,
        format: wgpu::TextureFormat,
        w: u32,
        h: u32,
    ) -> wgpu::Texture {
        device.create_texture(&wgpu::TextureDescriptor {
            label: Some("hdr-target"),
            size: wgpu::Extent3d { width: w, height: h, depth_or_array_layers: 1 },
            mip_level_count: 1,
            sample_count: 1,
            dimension: wgpu::TextureDimension::D2,
            format,
            usage: wgpu::TextureUsages::RENDER_ATTACHMENT | wgpu::TextureUsages::TEXTURE_BINDING,
            view_formats: &[],
        })
    }
}
