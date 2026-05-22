# DLSS / Streamline CVar cheatsheet

CVars and BP nodes for NVIDIA's upscaling stack via the **Streamline** plugin (recommended over standalone DLSS / FSR / XeSS plugins).

## Enable

Project Settings → Plugins → **Streamline** + **DLSS** → restart.

## CVars

### Master

| CVar | Effect |
| --- | --- |
| `r.NGX.Enable` | 1 to enable NGX (DLSS) |
| `r.NGX.DLSS.Enable` | 1 to allow DLSS |
| `r.NGX.DLSSG.Enable` | 1 to allow DLSS Frame Generation |
| `r.NGX.DLSSRR.Enable` | 1 to allow DLSS Ray Reconstruction |
| `r.NGX.Reflex.Enable` | 1 for Reflex low latency |

### DLSS Super Resolution

| CVar | Effect |
| --- | --- |
| `r.NGX.DLSS.Quality` | 0=DLAA, 1=Quality, 2=Balanced, 3=Performance, 4=Ultra Performance |
| `r.NGX.DLSS.AutoExposure` | 1 to let NGX do auto-exposure on the upscale input |
| `r.NGX.DLSS.UseTransientResources` | 1 for ephemeral buffer aliasing |

### Frame Generation

| CVar | Effect |
| --- | --- |
| `r.NGX.DLSSG.Mode` | 0=Off, 1=On, 2=On with multi-frame (RTX 40+) |

### Ray Reconstruction

| CVar | Effect |
| --- | --- |
| `r.NGX.DLSSRR.Enable` | Master toggle |
| `r.PathTracing.UseDLSSDenoiser` | 1 to use RR as the PT denoiser |

### Reflex

| CVar | Effect |
| --- | --- |
| `r.NGX.Reflex.Mode` | 0=Off, 1=On, 2=On+Boost |

## Blueprint API

```
DLSS Library → Set DLSS Mode (DLAA / Quality / Balanced / …)
DLSS Library → Is DLSS Supported
DLSS Library → Set DLSS Quality (combine with -1 = Auto for ScreenPercentage-driven)
DLSS Library → Set Frame Generation Mode
DLSS Library → Set Reflex Mode
DLSS Library → Set Reflex FPS Cap
```

## Settings UI pattern

Build a settings menu that:

1. Detects support via `IsDLSSSupported` and `IsFrameGenerationSupported`
2. Exposes Quality dropdown (DLAA / Quality / Balanced / Performance / Ultra Perf)
3. Frame Generation toggle (only if supported on RTX 40+)
4. Reflex dropdown (Off / On / On + Boost)
5. Auto-applies CVars on change

## Performance budget

| Mode | Internal res @ 4K | Quality |
| --- | --- | --- |
| DLAA | 4K | Highest, no upscale |
| Quality | 1440p | Near-native |
| Balanced | 1253p | Good |
| Performance | 1080p | OK |
| Ultra Performance | 720p | Aggressive (low-end) |

## Linked

- [Rendering → Pixel Streaming](https://jdot274.github.io/Prism-KB/rendering/pixel-streaming/)
- [Workflows → NVIDIA RTX Stack](https://jdot274.github.io/Prism-KB/workflows/nvidia-rtx-stack/)
