# Drone-cam PostProcess + Sequencer combo

Stack multiple Post Process Volumes for a cinematic drone camera shot.

## Setup

- **Volume A** — `Global` post-process: base look
  - Priority: 0
  - Unbound: true
- **Volume B** — `Drone Path` post-process: stylized
  - Priority: 10
  - Blend Radius: 500
  - Bounds: along the drone's flight path
  - Settings: Increase Bloom, slight chromatic aberration, color grading shift to teal
- **Volume C** — `Climax Beat` post-process: peak emotional moment
  - Priority: 20
  - Blend Radius: 200
  - Bounds: small box at the climax location
  - Settings: high vignette, time dilation via PPM material, motion blur boost

## Sequencer track

```
+ Track → Cine Camera
  Animate location + rotation through Volumes A, B, C
+ Track → Post Process (on the Cine Camera)
  Override Blend Weight: keyframe 0 → 1 → 0 over the shot
+ Event Track
  Fire BP event at climax to push a custom SoundMix
```

## Tips

- Use **PostProcessMaterial** Blendables for custom one-shot effects (lens flare, screen distortion)
- For LUT-based color grading, drop a `LUT_<Look>.uasset` in the volume's **Color Grading LUT** slot
- Pair with **Convolution Reverb** on an Audio Volume that matches the drone path
