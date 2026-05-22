use wgpu::util::DeviceExt;

// ---------------------------------------------------------------------------
// Uniforms
// ---------------------------------------------------------------------------

/// Per-frame uniforms for the colour-wheel shader.
///
/// Matches `ColorWheelGpuData` from `tools::color_wheel` field-for-field so
/// the caller can transmit that struct directly or copy individual fields.
///
/// # Layout (WGSL std140)
/// | Field          | Offset | Size |
/// |----------------|--------|------|
/// | `center`       | 0      | 8    |
/// | `outer_r`      | 8      | 4    |
/// | `inner_r`      | 12     | 4    |
/// | `selected_hue` | 16     | 4    |
/// | `selected_sat` | 20     | 4    |
/// | `selected_lum` | 24     | 4    |
/// | `_pad`         | 28     | 4    |
///
/// Total: 32 bytes.
#[repr(C)]
#[derive(Copy, Clone, bytemuck::Pod, bytemuck::Zeroable)]
pub struct WheelUniforms {
    /// Pixel-space centre of the wheel `[cx, cy]`.
    pub center: [f32; 2],
    /// Radius of the outer edge of the hue ring (pixels).
    pub outer_r: f32,
    /// Radius of the inner edge of the hue ring (pixels).
    pub inner_r: f32,
    /// Selected hue in `[0, 1)`.
    pub selected_hue: f32,
    /// Selected saturation in `[0, 1]`.
    pub selected_sat: f32,
    /// Selected luminance in `[0, 1]`.
    pub selected_lum: f32,
    /// Padding — do not use.
    pub _pad: f32,
}

// ---------------------------------------------------------------------------
// Pipeline
// ---------------------------------------------------------------------------

/// Renders the HSL colour-wheel overlay using a full-screen triangle.
///
/// No vertex buffer is used — the vertex shader generates the triangle from
/// `vertex_index`. The fragment shader reads `WheelUniforms` to know where to
/// draw the ring and triangle, discarding fragments outside both regions.
///
/// # Usage
/// ```ignore
/// let wheel_pipeline = ColorWheelPipeline::new(&device, surface_format);
///
/// // Each frame:
/// wheel_pipeline.update_uniforms(&queue, WheelUniforms { center, outer_r, inner_r, .. });
/// let mut rpass = encoder.begin_render_pass(&desc);
/// wheel_pipeline.draw(&mut rpass);
/// ```
pub struct ColorWheelPipeline {
    pipeline: wgpu::RenderPipeline,
    uniform_buf: wgpu::Buffer,
    bind_group: wgpu::BindGroup,
}

impl ColorWheelPipeline {
    /// Create a new `ColorWheelPipeline` targeting `format`.
    pub fn new(device: &wgpu::Device, format: wgpu::TextureFormat) -> Self {
        // --- Shader --------------------------------------------------------
        let shader = device.create_shader_module(wgpu::ShaderModuleDescriptor {
            label: Some("color_wheel_shader"),
            source: wgpu::ShaderSource::Wgsl(
                include_str!("../shaders/color_wheel.wgsl").into(),
            ),
        });

        // --- Uniform buffer ------------------------------------------------
        let uniform_buf = device.create_buffer_init(&wgpu::util::BufferInitDescriptor {
            label: Some("color_wheel_uniforms"),
            contents: bytemuck::bytes_of(&WheelUniforms {
                center: [0.0; 2],
                outer_r: 1.0,
                inner_r: 0.78,
                selected_hue: 0.0,
                selected_sat: 0.8,
                selected_lum: 0.5,
                _pad: 0.0,
            }),
            usage: wgpu::BufferUsages::UNIFORM | wgpu::BufferUsages::COPY_DST,
        });

        // --- Bind group layout ---------------------------------------------
        let bgl = device.create_bind_group_layout(&wgpu::BindGroupLayoutDescriptor {
            label: Some("color_wheel_bgl"),
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
            label: Some("color_wheel_bg"),
            layout: &bgl,
            entries: &[wgpu::BindGroupEntry {
                binding: 0,
                resource: uniform_buf.as_entire_binding(),
            }],
        });

        // --- Pipeline layout -----------------------------------------------
        let pipeline_layout = device.create_pipeline_layout(&wgpu::PipelineLayoutDescriptor {
            label: Some("color_wheel_pipeline_layout"),
            bind_group_layouts: &[&bgl],
            push_constant_ranges: &[],
        });

        // --- Render pipeline -----------------------------------------------
        // Full-screen triangle: no vertex buffers.
        let pipeline = device.create_render_pipeline(&wgpu::RenderPipelineDescriptor {
            label: Some("color_wheel_pipeline"),
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
                    blend: Some(wgpu::BlendState::ALPHA_BLENDING),
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
    /// Must be called before [`draw`](Self::draw) each frame.
    pub fn update_uniforms(&self, queue: &wgpu::Queue, uniforms: WheelUniforms) {
        queue.write_buffer(&self.uniform_buf, 0, bytemuck::bytes_of(&uniforms));
    }

    /// Record draw commands into `rpass`.
    pub fn draw<'a>(&'a self, rpass: &mut wgpu::RenderPass<'a>) {
        rpass.set_pipeline(&self.pipeline);
        rpass.set_bind_group(0, &self.bind_group, &[]);
        rpass.draw(0..3, 0..1);
    }
}
