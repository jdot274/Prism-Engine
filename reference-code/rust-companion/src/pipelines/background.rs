use wgpu::util::DeviceExt;

// ---------------------------------------------------------------------------
// Uniforms
// ---------------------------------------------------------------------------

/// Per-frame uniforms for the canvas background shader.
///
/// Uploaded once per frame via [`BackgroundPipeline::update_uniforms`].
///
/// # Layout (std140 / WGSL offset rules)
/// | Field        | Offset | Size |
/// |--------------|--------|------|
/// | `resolution` | 0      | 8    |
/// | `time`       | 8      | 4    |
/// | `_pad`       | 12     | 4    |
///
/// Total: 16 bytes (one WGSL `vec4<f32>`-aligned slot).
#[repr(C)]
#[derive(Copy, Clone, bytemuck::Pod, bytemuck::Zeroable)]
pub struct CanvasUniforms {
    /// Surface size in pixels: `[width, height]`.
    pub resolution: [f32; 2],
    /// Elapsed time in seconds since application start.
    pub time: f32,
    /// Padding — do not use.
    pub _pad: f32,
}

// ---------------------------------------------------------------------------
// Pipeline
// ---------------------------------------------------------------------------

/// Renders the animated canvas background using a full-screen triangle.
///
/// The pipeline owns its uniform buffer and bind group. No vertex buffer is
/// required — the vertex shader generates the triangle procedurally from
/// `vertex_index`.
///
/// # Usage
/// ```ignore
/// let bg = BackgroundPipeline::new(&device, surface_format);
///
/// // Each frame:
/// bg.update_uniforms(&queue, CanvasUniforms {
///     resolution: [width as f32, height as f32],
///     time: elapsed_secs,
///     _pad: 0.0,
/// });
/// let mut rpass = encoder.begin_render_pass(&desc);
/// bg.draw(&mut rpass);
/// ```
pub struct BackgroundPipeline {
    pipeline: wgpu::RenderPipeline,
    uniform_buf: wgpu::Buffer,
    bind_group: wgpu::BindGroup,
}

impl BackgroundPipeline {
    /// Create a new `BackgroundPipeline` targeting `format`.
    ///
    /// `device` must remain valid for the lifetime of this object.
    pub fn new(device: &wgpu::Device, format: wgpu::TextureFormat) -> Self {
        // --- Shader --------------------------------------------------------
        let shader = device.create_shader_module(wgpu::ShaderModuleDescriptor {
            label: Some("background_shader"),
            source: wgpu::ShaderSource::Wgsl(
                include_str!("../shaders/background.wgsl").into(),
            ),
        });

        // --- Uniform buffer ------------------------------------------------
        let uniform_buf = device.create_buffer_init(&wgpu::util::BufferInitDescriptor {
            label: Some("background_uniforms"),
            contents: bytemuck::bytes_of(&CanvasUniforms {
                resolution: [1.0, 1.0],
                time: 0.0,
                _pad: 0.0,
            }),
            usage: wgpu::BufferUsages::UNIFORM | wgpu::BufferUsages::COPY_DST,
        });

        // --- Bind group layout ---------------------------------------------
        let bgl = device.create_bind_group_layout(&wgpu::BindGroupLayoutDescriptor {
            label: Some("background_bgl"),
            entries: &[wgpu::BindGroupLayoutEntry {
                binding: 0,
                visibility: wgpu::ShaderStages::FRAGMENT,
                ty: wgpu::BindingType::Buffer {
                    ty: wgpu::BufferBindingType::Uniform,
                    has_dynamic_offset: false,
                    min_binding_size: None,
                },
                count: None,
            }],
        });

        // --- Bind group ----------------------------------------------------
        let bind_group = device.create_bind_group(&wgpu::BindGroupDescriptor {
            label: Some("background_bg"),
            layout: &bgl,
            entries: &[wgpu::BindGroupEntry {
                binding: 0,
                resource: uniform_buf.as_entire_binding(),
            }],
        });

        // --- Pipeline layout -----------------------------------------------
        let pipeline_layout = device.create_pipeline_layout(&wgpu::PipelineLayoutDescriptor {
            label: Some("background_pipeline_layout"),
            bind_group_layouts: &[&bgl],
            push_constant_ranges: &[],
        });

        // --- Render pipeline -----------------------------------------------
        // Full-screen triangle: no vertex buffers, 3 procedural vertices.
        let pipeline = device.create_render_pipeline(&wgpu::RenderPipelineDescriptor {
            label: Some("background_pipeline"),
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
                strip_index_format: None,
                front_face: wgpu::FrontFace::Ccw,
                cull_mode: None,
                polygon_mode: wgpu::PolygonMode::Fill,
                unclipped_depth: false,
                conservative: false,
            },
            depth_stencil: None,
            multisample: wgpu::MultisampleState::default(),
            multiview: None,
            cache: None,
        });

        Self {
            pipeline,
            uniform_buf,
            bind_group,
        }
    }

    /// Upload new uniform data to the GPU.
    ///
    /// Call once per frame before [`draw`](Self::draw).
    pub fn update_uniforms(&self, queue: &wgpu::Queue, uniforms: CanvasUniforms) {
        queue.write_buffer(&self.uniform_buf, 0, bytemuck::bytes_of(&uniforms));
    }

    /// Record draw commands into `rpass`.
    ///
    /// The render pass must target a texture whose format matches the one
    /// supplied to [`new`](Self::new).
    pub fn draw<'a>(&'a self, rpass: &mut wgpu::RenderPass<'a>) {
        rpass.set_pipeline(&self.pipeline);
        rpass.set_bind_group(0, &self.bind_group, &[]);
        rpass.draw(0..3, 0..1);
    }
}
