use wgpu::util::DeviceExt;

// Matches BloomUniforms in bloom.wgsl (32 bytes total)
#[repr(C)]
#[derive(Copy, Clone, bytemuck::Pod, bytemuck::Zeroable)]
struct BloomUniforms {
    resolution: [f32; 2],
    pass: u32,
    threshold: f32,
    bloom_intensity: f32,
    blur_radius: f32,
    state_bloom_scale: f32,
    _pad: f32,
}

fn make_tex(
    device: &wgpu::Device,
    format: wgpu::TextureFormat,
    w: u32,
    h: u32,
    label: &str,
) -> (wgpu::Texture, wgpu::TextureView) {
    let tex = device.create_texture(&wgpu::TextureDescriptor {
        label: Some(label),
        size: wgpu::Extent3d { width: w, height: h, depth_or_array_layers: 1 },
        mip_level_count: 1,
        sample_count: 1,
        dimension: wgpu::TextureDimension::D2,
        format,
        usage: wgpu::TextureUsages::RENDER_ATTACHMENT | wgpu::TextureUsages::TEXTURE_BINDING,
        view_formats: &[],
    });
    let view = tex.create_view(&Default::default());
    (tex, view)
}

/// Four-pass bloom: threshold → blur_h → blur_v → composite+tonemap.
/// Each pass runs in its own encoder+submit so the single uniform buffer
/// can be updated between passes without aliasing.
pub struct BloomPipeline {
    pipeline: wgpu::RenderPipeline,
    bgl: wgpu::BindGroupLayout,
    uniform_buf: wgpu::Buffer,
    sampler: wgpu::Sampler,
    ping_tex: wgpu::Texture,
    ping_view: wgpu::TextureView,
    pong_tex: wgpu::Texture,
    pong_view: wgpu::TextureView,
    dummy_tex: wgpu::Texture,
    dummy_view: wgpu::TextureView,
    width: u32,
    height: u32,
}

impl BloomPipeline {
    pub fn new(device: &wgpu::Device, format: wgpu::TextureFormat, w: u32, h: u32) -> Self {
        let shader = device.create_shader_module(wgpu::ShaderModuleDescriptor {
            label: Some("bloom_shader"),
            source: wgpu::ShaderSource::Wgsl(include_str!("../shaders/bloom.wgsl").into()),
        });

        // BGL mirrors bloom.wgsl: 0=uniforms, 1=t_scene, 2=s_scene, 3=t_bloom, 4=s_bloom
        let bgl = device.create_bind_group_layout(&wgpu::BindGroupLayoutDescriptor {
            label: Some("bloom_bgl"),
            entries: &[
                wgpu::BindGroupLayoutEntry {
                    binding: 0,
                    visibility: wgpu::ShaderStages::FRAGMENT,
                    ty: wgpu::BindingType::Buffer {
                        ty: wgpu::BufferBindingType::Uniform,
                        has_dynamic_offset: false,
                        min_binding_size: None,
                    },
                    count: None,
                },
                wgpu::BindGroupLayoutEntry {
                    binding: 1,
                    visibility: wgpu::ShaderStages::FRAGMENT,
                    ty: wgpu::BindingType::Texture {
                        sample_type: wgpu::TextureSampleType::Float { filterable: true },
                        view_dimension: wgpu::TextureViewDimension::D2,
                        multisampled: false,
                    },
                    count: None,
                },
                wgpu::BindGroupLayoutEntry {
                    binding: 2,
                    visibility: wgpu::ShaderStages::FRAGMENT,
                    ty: wgpu::BindingType::Sampler(wgpu::SamplerBindingType::Filtering),
                    count: None,
                },
                wgpu::BindGroupLayoutEntry {
                    binding: 3,
                    visibility: wgpu::ShaderStages::FRAGMENT,
                    ty: wgpu::BindingType::Texture {
                        sample_type: wgpu::TextureSampleType::Float { filterable: true },
                        view_dimension: wgpu::TextureViewDimension::D2,
                        multisampled: false,
                    },
                    count: None,
                },
                wgpu::BindGroupLayoutEntry {
                    binding: 4,
                    visibility: wgpu::ShaderStages::FRAGMENT,
                    ty: wgpu::BindingType::Sampler(wgpu::SamplerBindingType::Filtering),
                    count: None,
                },
            ],
        });

        let uniform_buf = device.create_buffer_init(&wgpu::util::BufferInitDescriptor {
            label: Some("bloom_uniforms"),
            contents: bytemuck::bytes_of(&BloomUniforms {
                resolution: [w as f32, h as f32],
                pass: 0,
                threshold: 0.8,
                bloom_intensity: 0.15,
                blur_radius: 4.0,
                state_bloom_scale: 1.0,
                _pad: 0.0,
            }),
            usage: wgpu::BufferUsages::UNIFORM | wgpu::BufferUsages::COPY_DST,
        });

        let sampler = device.create_sampler(&wgpu::SamplerDescriptor {
            label: Some("bloom_sampler"),
            address_mode_u: wgpu::AddressMode::ClampToEdge,
            address_mode_v: wgpu::AddressMode::ClampToEdge,
            mag_filter: wgpu::FilterMode::Linear,
            min_filter: wgpu::FilterMode::Linear,
            ..Default::default()
        });

        let pipeline_layout = device.create_pipeline_layout(&wgpu::PipelineLayoutDescriptor {
            label: Some("bloom_pipeline_layout"),
            bind_group_layouts: &[&bgl],
            push_constant_ranges: &[],
        });

        let pipeline = device.create_render_pipeline(&wgpu::RenderPipelineDescriptor {
            label: Some("bloom_pipeline"),
            layout: Some(&pipeline_layout),
            vertex: wgpu::VertexState {
                module: &shader,
                entry_point: Some("vs_main"),
                buffers: &[],
                compilation_options: wgpu::PipelineCompilationOptions::default(),
            },
            fragment: Some(wgpu::FragmentState {
                module: &shader,
                entry_point: Some("fs_main"),
                targets: &[Some(wgpu::ColorTargetState {
                    format,
                    blend: Some(wgpu::BlendState::REPLACE),
                    write_mask: wgpu::ColorWrites::ALL,
                })],
                compilation_options: wgpu::PipelineCompilationOptions::default(),
            }),
            primitive: wgpu::PrimitiveState {
                topology: wgpu::PrimitiveTopology::TriangleList,
                cull_mode: None,
                ..Default::default()
            },
            depth_stencil: None,
            multisample: wgpu::MultisampleState::default(),
            multiview: None,
            cache: None,
        });

        let (ping_tex, ping_view) = make_tex(device, format, w, h, "bloom_ping");
        let (pong_tex, pong_view) = make_tex(device, format, w, h, "bloom_pong");
        let (dummy_tex, dummy_view) = make_tex(device, format, 1, 1, "bloom_dummy");

        Self {
            pipeline,
            bgl,
            uniform_buf,
            sampler,
            ping_tex,
            ping_view,
            pong_tex,
            pong_view,
            dummy_tex,
            dummy_view,
            width: w,
            height: h,
        }
    }

    pub fn resize(&mut self, device: &wgpu::Device, w: u32, h: u32) {
        let fmt = self.ping_tex.format();
        let (ping_tex, ping_view) = make_tex(device, fmt, w, h, "bloom_ping");
        let (pong_tex, pong_view) = make_tex(device, fmt, w, h, "bloom_pong");
        self.ping_tex = ping_tex;
        self.ping_view = ping_view;
        self.pong_tex = pong_tex;
        self.pong_view = pong_view;
        self.width = w;
        self.height = h;
    }

    /// Run all 4 bloom passes and write tonemapped output to `output_view`.
    /// Takes `device` so bind groups can be created per-pass against current views.
    pub fn apply(
        &self,
        device: &wgpu::Device,
        queue: &wgpu::Queue,
        scene_view: &wgpu::TextureView,
        output_view: &wgpu::TextureView,
    ) {
        let res = [self.width as f32, self.height as f32];

        // (pass_idx, t_scene, t_bloom, render_target)
        let passes: [(u32, &wgpu::TextureView, &wgpu::TextureView, &wgpu::TextureView); 4] = [
            (0, scene_view,       &self.dummy_view, &self.ping_view),
            (1, &self.ping_view,  &self.dummy_view, &self.pong_view),
            (2, &self.dummy_view, &self.pong_view,  &self.ping_view),
            (3, scene_view,       &self.ping_view,  output_view),
        ];

        for (pass_idx, t_scene, t_bloom, target) in &passes {
            queue.write_buffer(
                &self.uniform_buf,
                0,
                bytemuck::bytes_of(&BloomUniforms {
                    resolution: res,
                    pass: *pass_idx,
                    threshold: 0.8,
                    bloom_intensity: 0.15,
                    blur_radius: 4.0,
                    state_bloom_scale: 1.0,
                    _pad: 0.0,
                }),
            );

            let bg = device.create_bind_group(&wgpu::BindGroupDescriptor {
                label: Some("bloom_bg"),
                layout: &self.bgl,
                entries: &[
                    wgpu::BindGroupEntry {
                        binding: 0,
                        resource: self.uniform_buf.as_entire_binding(),
                    },
                    wgpu::BindGroupEntry {
                        binding: 1,
                        resource: wgpu::BindingResource::TextureView(t_scene),
                    },
                    wgpu::BindGroupEntry {
                        binding: 2,
                        resource: wgpu::BindingResource::Sampler(&self.sampler),
                    },
                    wgpu::BindGroupEntry {
                        binding: 3,
                        resource: wgpu::BindingResource::TextureView(t_bloom),
                    },
                    wgpu::BindGroupEntry {
                        binding: 4,
                        resource: wgpu::BindingResource::Sampler(&self.sampler),
                    },
                ],
            });

            let mut encoder = device.create_command_encoder(
                &wgpu::CommandEncoderDescriptor { label: Some("bloom_pass") },
            );
            {
                let mut rpass = encoder.begin_render_pass(&wgpu::RenderPassDescriptor {
                    label: Some("bloom_rpass"),
                    color_attachments: &[Some(wgpu::RenderPassColorAttachment {
                        view: target,
                        resolve_target: None,
                        ops: wgpu::Operations {
                            load: wgpu::LoadOp::Clear(wgpu::Color::BLACK),
                            store: wgpu::StoreOp::Store,
                        },
                    })],
                    depth_stencil_attachment: None,
                    timestamp_writes: None,
                    occlusion_query_set: None,
                });
                rpass.set_pipeline(&self.pipeline);
                rpass.set_bind_group(0, &bg, &[]);
                rpass.draw(0..3, 0..1);
            }
            queue.submit(std::iter::once(encoder.finish()));
        }
    }
}
