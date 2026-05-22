use wgpu::util::DeviceExt;

// ---------------------------------------------------------------------------
// Vertex
// ---------------------------------------------------------------------------

/// A single vertex of the card quad.
///
/// The six vertices form two CCW triangles covering the NDC square `[-1, 1]²`.
/// The vertex shader is expected to transform them using `CardUniforms.pos`
/// and `CardUniforms.size` into the correct screen-space rectangle.
#[repr(C)]
#[derive(Copy, Clone, bytemuck::Pod, bytemuck::Zeroable)]
pub struct CardVertex {
    /// Normalised position in `[-1, 1]²` — treated as a local-space anchor
    /// that the shader maps to the card's screen rect.
    pub position: [f32; 2],
    /// UV coordinates in `[0, 1]²` for the card body texture / SDF effects.
    pub uv: [f32; 2],
}

// ---------------------------------------------------------------------------
// Uniforms
// ---------------------------------------------------------------------------

/// Per-card uniforms for the card shader.
///
/// # Layout
/// | Field          | Offset | Size |
/// |----------------|--------|------|
/// | `pos`          | 0      | 8    |
/// | `size`         | 8      | 8    |
/// | `resolution`   | 16     | 8    |
/// | `accent_color` | 24     | 16   |
/// | `hover_t`      | 40     | 4    |
/// | `_pad`         | 44     | 12   |
///
/// Total: 56 bytes.
#[repr(C)]
#[derive(Copy, Clone, bytemuck::Pod, bytemuck::Zeroable)]
pub struct CardUniforms {
    /// Top-left corner of the card in pixel-space.
    pub pos: [f32; 2],
    /// Width and height of the card in pixels.
    pub size: [f32; 2],
    /// Surface resolution in pixels `[width, height]` (for NDC conversion).
    pub resolution: [f32; 2],
    /// Accent / tint colour in linear RGBA.
    pub accent_color: [f32; 4],
    /// Hover animation progress in `[0, 1]`.
    pub hover_t: f32,
    /// Padding — do not use.
    pub _pad: [f32; 3],
}

// ---------------------------------------------------------------------------
// Quad geometry (CCW, two triangles)
// ---------------------------------------------------------------------------

/// Pre-built quad covering NDC `[-1, 1]²` with UV `[0, 1]²`.
///
/// Triangle 0: bottom-left, bottom-right, top-right
/// Triangle 1: bottom-left, top-right,   top-left
const QUAD_VERTICES: [CardVertex; 6] = [
    // Triangle 0
    CardVertex { position: [-1.0, -1.0], uv: [0.0, 1.0] },
    CardVertex { position: [ 1.0, -1.0], uv: [1.0, 1.0] },
    CardVertex { position: [ 1.0,  1.0], uv: [1.0, 0.0] },
    // Triangle 1
    CardVertex { position: [-1.0, -1.0], uv: [0.0, 1.0] },
    CardVertex { position: [ 1.0,  1.0], uv: [1.0, 0.0] },
    CardVertex { position: [-1.0,  1.0], uv: [0.0, 0.0] },
];

// ---------------------------------------------------------------------------
// Pipeline
// ---------------------------------------------------------------------------

/// Renders a single floating card using a quad (6 vertices, 2 triangles).
///
/// Cards are rendered one at a time; the caller is responsible for issuing one
/// `update_uniforms` + `draw` pair per visible card per frame.
///
/// # Usage
/// ```ignore
/// let card_pipeline = CardPipeline::new(&device, surface_format);
///
/// // Per card, per frame:
/// card_pipeline.update_uniforms(&queue, CardUniforms { pos, size, resolution, accent_color, hover_t, _pad: [0.0; 3] });
/// let mut rpass = encoder.begin_render_pass(&desc);
/// card_pipeline.draw(&mut rpass);
/// ```
pub struct CardPipeline {
    pipeline: wgpu::RenderPipeline,
    vertex_buf: wgpu::Buffer,
    uniform_buf: wgpu::Buffer,
    bind_group: wgpu::BindGroup,
}

impl CardPipeline {
    /// Create a new `CardPipeline` targeting `format`.
    pub fn new(device: &wgpu::Device, format: wgpu::TextureFormat) -> Self {
        // --- Shader --------------------------------------------------------
        let shader = device.create_shader_module(wgpu::ShaderModuleDescriptor {
            label: Some("card_shader"),
            source: wgpu::ShaderSource::Wgsl(include_str!("../shaders/card.wgsl").into()),
        });

        // --- Vertex buffer -------------------------------------------------
        let vertex_buf = device.create_buffer_init(&wgpu::util::BufferInitDescriptor {
            label: Some("card_vertex_buf"),
            contents: bytemuck::cast_slice(&QUAD_VERTICES),
            usage: wgpu::BufferUsages::VERTEX,
        });

        // --- Uniform buffer ------------------------------------------------
        let uniform_buf = device.create_buffer_init(&wgpu::util::BufferInitDescriptor {
            label: Some("card_uniforms"),
            contents: bytemuck::bytes_of(&CardUniforms {
                pos: [0.0; 2],
                size: [1.0, 1.0],
                resolution: [1.0, 1.0],
                accent_color: [1.0; 4],
                hover_t: 0.0,
                _pad: [0.0; 3],
            }),
            usage: wgpu::BufferUsages::UNIFORM | wgpu::BufferUsages::COPY_DST,
        });

        // --- Bind group layout ---------------------------------------------
        let bgl = device.create_bind_group_layout(&wgpu::BindGroupLayoutDescriptor {
            label: Some("card_bgl"),
            entries: &[wgpu::BindGroupLayoutEntry {
                binding: 0,
                visibility: wgpu::ShaderStages::VERTEX | wgpu::ShaderStages::FRAGMENT,
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
            label: Some("card_bg"),
            layout: &bgl,
            entries: &[wgpu::BindGroupEntry {
                binding: 0,
                resource: uniform_buf.as_entire_binding(),
            }],
        });

        // --- Pipeline layout -----------------------------------------------
        let pipeline_layout = device.create_pipeline_layout(&wgpu::PipelineLayoutDescriptor {
            label: Some("card_pipeline_layout"),
            bind_group_layouts: &[&bgl],
            push_constant_ranges: &[],
        });

        // --- Vertex buffer layout ------------------------------------------
        let vertex_layout = wgpu::VertexBufferLayout {
            array_stride: std::mem::size_of::<CardVertex>() as wgpu::BufferAddress,
            step_mode: wgpu::VertexStepMode::Vertex,
            attributes: &wgpu::vertex_attr_array![
                0 => Float32x2, // position
                1 => Float32x2, // uv
            ],
        };

        // --- Render pipeline -----------------------------------------------
        let pipeline = device.create_render_pipeline(&wgpu::RenderPipelineDescriptor {
            label: Some("card_pipeline"),
            layout: Some(&pipeline_layout),
            vertex: wgpu::VertexState {
                module: &shader,
                entry_point: Some("vs_main"),
                buffers: &[vertex_layout],
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
            vertex_buf,
            uniform_buf,
            bind_group,
        }
    }

    /// Upload new per-card uniform data to the GPU.
    ///
    /// Must be called before [`draw`](Self::draw) for each card each frame.
    pub fn update_uniforms(&self, queue: &wgpu::Queue, uniforms: CardUniforms) {
        queue.write_buffer(&self.uniform_buf, 0, bytemuck::bytes_of(&uniforms));
    }

    /// Record draw commands for one card into `rpass`.
    pub fn draw<'a>(&'a self, rpass: &mut wgpu::RenderPass<'a>) {
        rpass.set_pipeline(&self.pipeline);
        rpass.set_bind_group(0, &self.bind_group, &[]);
        rpass.set_vertex_buffer(0, self.vertex_buf.slice(..));
        rpass.draw(0..6, 0..1);
    }
}
