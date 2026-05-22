# Prism Visual Identity System
**Version 1.0 — May 2026**
*Art Direction: Prism Design Suite*

---

> **Design Principle:** Glow is earned, never decorative. Color is a signal, not a finish.
> Every luminous moment must carry meaning. Silence is the canvas; light is the language.

---

## 1. Color System

### 1.1 Background Palette

The foundation of Prism is near-absolute darkness. Not pure black — pure black reads as a void and flattens depth. Prism's blacks have a barely-perceptible cool blue undertone that makes surfaces feel like anodized metal or tempered glass rather than a hole in the screen.

| Role                  | Name             | Hex       | HSL                   | Usage                                                      |
|-----------------------|------------------|-----------|-----------------------|------------------------------------------------------------|
| Canvas                | `void`           | `#080A0E` | `hsl(220, 30%, 5%)`   | The base layer: the infinite workspace canvas              |
| Surface 0             | `obsidian`       | `#0D1117` | `hsl(216, 28%, 7%)`   | App chrome, side rails, launcher background                |
| Surface 1             | `slate-deep`     | `#111622` | `hsl(220, 32%, 10%)`  | Default card background, closed panels                     |
| Surface 2             | `slate-mid`      | `#161D2E` | `hsl(222, 34%, 14%)`  | Elevated cards, open dropdowns, tooltip backgrounds        |
| Surface 3             | `slate-high`     | `#1C2540` | `hsl(226, 38%, 18%)`  | Modals, context menus, highest elevation                   |
| Hairline              | `edge-subtle`    | `#1F2B42` | `hsl(220, 34%, 19%)`  | 1px borders at elevation transitions, dividers             |
| Hairline (bright)     | `edge-accent`    | `#2A3A58` | `hsl(220, 36%, 25%)`  | Borders on active/focused cards, selected states           |

**Elevation Rule:** Each surface layer is perceptible only at close range — the difference between Surface 0 and Surface 1 is intentionally subtle (3% lightness delta). Elevation is communicated through *shadow and glow*, not dramatic background changes. A card does not lighten to float; it casts a shadow and emits a faint rim light.

---

### 1.2 Accent Colors — The Glow Palette

These are the prismatic accent colors. They are derived from a full HSL rotation, selecting hues at maximum perceptual vividness against the dark ground. Each has three tiers: **dim** (passive glow, default interactive), **base** (hover, selected), and **bloom** (active, pressed, confirmed).

The glow palette should never appear simultaneously in full saturation. One dominant accent per context. Secondary accents must be suppressed to their dim tier.

| Name        | Hex (base)  | HSL (base)              | Dim Hex     | Bloom Hex   | Semantic Use                                    |
|-------------|-------------|-------------------------|-------------|-------------|-------------------------------------------------|
| `prism-red`     | `#FF3D5A` | `hsl(349, 100%, 62%)`   | `#7A1A28`   | `#FF6680`   | Destructive actions, pitch/frequency tools      |
| `prism-orange`  | `#FF6B1A` | `hsl(24, 100%, 55%)`    | `#7A3208`   | `#FF8C4D`   | Warmth tools, analog emulation, recording state |
| `prism-amber`   | `#FFBB00` | `hsl(44, 100%, 50%)`    | `#7A5800`   | `#FFD04D`   | Caution, level meters, quantization overlays    |
| `prism-lime`    | `#A8FF00` | `hsl(74, 100%, 50%)`    | `#506200`   | `#BEFF4D`   | Confirmation, midi routing, patch connections   |
| `prism-cyan`    | `#00F5FF` | `hsl(183, 100%, 50%)`   | `#007880`   | `#66F8FF`   | Primary interactive: selection, focus rings     |
| `prism-violet`  | `#8B5CF6` | `hsl(258, 89%, 66%)`    | `#3D1A80`   | `#A67EF8`   | Creative/generative tools, AI-assist states     |
| `prism-magenta` | `#FF2DCA` | `hsl(312, 100%, 59%)`   | `#7A0062`   | `#FF66DB`   | Modulation routing, LFO connections             |

**Primary Interactive Accent:** `prism-cyan` (`#00F5FF`) is the system-wide default for focus rings, selection halos, and the active tool indicator in the launcher rail. It reads cleanest against the near-black backgrounds and has the highest contrast ratio of the palette.

---

### 1.3 Semantic Colors

Semantic colors communicate state. They must feel luminous — they are not flat Material Design chips but glowing indicators with inner light. Each semantic color is paired with a glow shadow for use in active states.

| State   | Base Hex    | Glow (box-shadow color) | Background Tint | Description                                 |
|---------|-------------|-------------------------|-----------------|---------------------------------------------|
| Error   | `#FF3D5A`   | `#FF3D5A40`             | `#FF3D5A12`     | Critical failure, invalid input, hard stop  |
| Warning | `#FFBB00`   | `#FFBB0040`             | `#FFBB0012`     | Non-critical, recoverable, attention needed |
| Success | `#A8FF00`   | `#A8FF0040`             | `#A8FF0012`     | Confirmed, rendered, exported, connected    |
| Info    | `#00F5FF`   | `#00F5FF40`             | `#00F5FF12`     | Neutral status, hints, system messages      |

Semantic banners and toasts use the background tint as a card fill behind the message, with a 1px border in the base color at 60% opacity. The icon accompanying the message uses the base color at full opacity. No filled solid-color chips. Everything is dark with a luminous edge.

---

### 1.4 The Color Permission Rule

**Color is suppressed by default. Color is unlocked by meaning.**

| Condition                              | Allowed Color                           |
|----------------------------------------|-----------------------------------------|
| Idle, unfocused UI element             | Monochrome only (`#3A4A66` and below)   |
| Hovered interactive element            | Dim tier accent only                    |
| Focused / keyboard-active element      | Base tier accent (focus ring)           |
| Selected, active, or pressed state     | Base or Bloom tier accent               |
| Confirmed action / success feedback    | Full glow: base + bloom shadow          |
| Semantic state (error/warn/success)    | Semantic color at prescribed opacity    |
| The color wheel or gradient tool UI    | Full HSL spectrum (tool-specific only)  |
| Decorative element / illustration      | NEVER. All decoration must be greyscale |

This rule means a Prism workspace at rest is almost entirely monochrome. The moment a user touches something, color responds. Glow acknowledges intent. Saturation is the reward for action.

---

## 2. Icon System

### 2.1 Icon Style

Prism launcher icons are **3D-rendered objects with physical presence.** They are not flat SVGs with drop shadows faked in CSS. Each icon is a crafted miniature object that appears to occupy a small volume of space, lit from a consistent world direction.

**Material Quality:**
Icons use one of three material archetypes, assigned by tool category:

| Archetype       | Material Description                                                         | Example Tools                       |
|-----------------|------------------------------------------------------------------------------|-------------------------------------|
| `matte-glass`   | Frosted borosilicate — translucent, refracts the background glow, soft edges | Color Picker, Gradient Map, Palette |
| `anodized-metal`| Brushed aluminium with subtle iridescent coating — cool, precise, technical  | Curve Editor, Grid, Measure, Export |
| `luminous-core` | Dense inner-lit form — glows from within, feels energetic and alive          | HSL Wheel, LFO, Oscilloscope, VFX   |

**No mixing archetypes within a single icon.** Sub-elements (e.g., a handle on a glass knob) may use a secondary archetype at reduced scale, but the dominant read must be one material.

---

### 2.2 Lighting Setup

All icons share a single world-space lighting rig. This is non-negotiable — inconsistent light direction is the fastest way to break the illusion of a coherent physical space.

```
Key Light:    Upper-left, 45° elevation, 30° azimuth left of center
              Color: #E8F0FF (cool white, slightly blue-shifted)
              Intensity: 1.8 (in Blender EEVEE units)
              Type: Area light, 0.3m × 0.3m, at 1.5m distance

Rim Light:    Lower-right, 20° elevation, 120° azimuth right of center
              Color: #4433FF (deep violet-blue — this is the "Prism rim")
              Intensity: 0.6
              Type: Point light

Fill Light:   Directly above, 90° elevation
              Color: #1A2240 (near-black, barely visible — prevents pure shadow crush)
              Intensity: 0.2
              Type: Area light, broad, 1m × 1m

HDRI Base:    Dark studio HDRI, rotated so brightest band aligns with key light
              Exposure: −2 EV (keeps environment contribution minimal)
```

The violet rim light (`#4433FF`) is the signature. It traces the silhouette of every icon with a faint purple-blue edge — barely perceptible at idle, intensifying on hover. This is what ties the diverse icon shapes into a single family.

---

### 2.3 Glow / Bloom Rule

| State    | Glow Radius | Glow Color                              | Glow Opacity | Bloom Layer |
|----------|-------------|------------------------------------------|--------------|-------------|
| Idle     | 0px         | —                                        | 0%           | None        |
| Hover    | 12px        | Category accent (dim tier)               | 40%          | None        |
| Active   | 20px        | Category accent (base tier)              | 70%          | Yes (0.3x)  |
| Selected | 28px        | Category accent (bloom tier)             | 90%          | Yes (0.6x)  |

**Bloom Layer:** A secondary light burst rendered at lower resolution and additively composited. In the rendered icon asset itself, the glow is baked in at each state. In the UI compositor (Unreal's UMG or equivalent), a `UTexture2D` glow pass is applied additively on top.

The backing card's `edge-accent` border (`#2A3A58`) brightens to the category accent color at base tier opacity when the icon is selected.

---

### 2.4 Icon Grid Specification

```
Canvas:         72 × 72dp
Icon safe zone: 48 × 48dp (centered, 12dp margin all sides)
Optical bleed:  Icons with glow/aura may extend 4dp into the margin
                (hard clip at canvas edge — never bleed outside 72dp)

Backing card:
  Size:          64 × 64dp (4dp inset from canvas edge on all sides)
  Corner radius: 14dp
  Fill:          Surface 1 (#111622) at 80% opacity
  Border:        1px, edge-subtle (#1F2B42), 100% opacity
  Selected border: 1px, category accent (base tier), 100% opacity

Icon proportions:
  Primary form fills 60% of safe zone height (approx. 29dp tall)
  Negative space is intentional — icons breathe
  No icon should touch two opposite edges of the safe zone simultaneously
```

---

### 2.5 Icon Categories and Visual Differentiation

Categories are distinguished by **dominant accent color family** applied to the icon's emissive/glow elements. The material archetype and shape language provide secondary differentiation.

| Category         | Accent Family   | Shape Language                          | Material Archetype  |
|------------------|-----------------|------------------------------------------|---------------------|
| Color Tools      | Cyan / Magenta  | Circular, radial, soft curves            | `matte-glass`       |
| Geometry / Grid  | Amber           | Rectilinear, precise, right angles       | `anodized-metal`    |
| Audio / Signal   | Lime / Orange   | Waveforms, sine curves, organic flow     | `luminous-core`     |
| Generative / AI  | Violet          | Fractal-adjacent, recursive, layered     | `luminous-core`     |
| Export / System  | Neutral (white) | Simple, universal glyphs, arrow motifs   | `anodized-metal`    |
| Effects / VFX    | Magenta / Red   | Explosive, radiant, starburst forms      | `luminous-core`     |
| Typography       | Cyan            | Letterform silhouettes, baseline rules   | `matte-glass`       |

Within a category, individual icons are distinguished by their primary silhouette. Color family is consistent across the category; silhouette is the identifier. A user should be able to locate a tool by shape in peripheral vision and confirm it by glow color on focus.

---

### 2.6 Render Pipeline Recommendation

**Recommended: Blender 4.x with EEVEE Next**

Rationale: EEVEE Next (Blender 4.2+) provides physically-based bloom, screen-space reflections, and volumetric glow that closely approximates the Prism aesthetic. Cycles is not recommended — render times per icon are prohibitive for a 50–100 icon library, and the subtle glow effects are more controllable in EEVEE's real-time compositor.

**Render Setup:**

```
Resolution:     512 × 512px per icon (delivered 2× for retina: 144dp physical)
Format:         PNG-32 (RGBA, sRGB color space)
Bloom:          EEVEE bloom enabled, threshold 0.8, radius 4, intensity 0.15
                (Subtle in base render — UI compositor adds state-specific glow)
Depth of Field: OFF (icons are read as diagrams, not photographs)
Motion Blur:    OFF
Background:     Pure alpha (no background object in scene)
Ambient Occlusion: ON, 0.5 intensity, 0.3m distance

Camera:
  Type:         Orthographic (no perspective distortion)
  Scale:        1.8 (fits icon comfortably in frame with bleed room)
  Position:     0, −5, 0 (front-facing, Y-axis toward camera)
  Rotation:     80° around X-axis (slight top-down tilt: 10° from straight-on)
  This tilt gives physical presence without going full 3/4 view isometric.
```

**Naming Convention for Rendered Icons:**

```
ui_icon_[category]_[toolname]_[state]_512.png
Examples:
  ui_icon_color_hslwheel_idle_512.png
  ui_icon_color_hslwheel_selected_512.png
  ui_icon_geometry_grid_hover_512.png
  ui_icon_system_export_idle_512.png
```

**Alternative Pipeline:** Cinema 4D + Redshift is acceptable for studios that prefer C4D's modelling workflow. Output specifications are identical. Unreal Engine's own rendering pipeline (Path Tracer) is viable but not recommended for icon production due to scene management overhead for 200–400 individual renders.

---

## 3. Card Aesthetic

Each Prism tool lives in a **480 × 480dp floating square card.** Cards are the primary interaction surface. They must feel simultaneously weightless (they float above the canvas without anchoring) and physical (they have real depth, real shadows, real material).

### 3.1 Card Surface

```
Dimensions:        480 × 480dp
Corner radius:     16dp (consistent with iOS/Material premium tier — feels intentional, not generic)
Fill:              Surface 1 (#111622) at 92% opacity
                   (8% opacity to canvas lets through the faintest breath of the canvas below)
Backdrop filter:   blur(24px) + saturate(120%)
                   (The card has a very subtle frosted glass quality — barely perceptible,
                    enhances depth perception on complex canvases)

Border:
  Default:         1px, edge-subtle (#1F2B42), 60% opacity
  Focused:         1px, edge-accent (#2A3A58), 100% opacity
  Active:          1px, prism-cyan dim (#007880), 100% opacity + inner glow

Inner glow (active state only):
  Type:            Inset box-shadow
  Color:           #00F5FF18
  Blur:            32px
  Spread:          0px
  (This makes the card subtly luminous from the inside when a tool is actively processing)
```

---

### 3.2 Header Bar

```
Height:            36dp
Background:        Surface 2 (#161D2E) at 100% opacity
                   (Slightly elevated from card body — creates a physical shelf feel)
Border-bottom:     1px, edge-subtle (#1F2B42), 100% opacity

Left zone:         Tool icon (20dp × 20dp, at 60% opacity idle, 100% on card focus)
                   + Tool name (see Typography section)
                   Icon + name group has 12dp left padding

Right zone:        Window controls at 12dp right padding
  Close button:    8dp × 8dp circle, fill #FF3D5A at 0% opacity idle
                   On card hover: fill #FF3D5A at 80% opacity + 6px glow
  Minimize button: 8dp × 8dp circle, fill #FFBB00 at 0% opacity idle
                   On card hover: fill #FFBB00 at 80% opacity + 6px glow
  Spacing:         8dp between buttons

  (Controls are invisible at rest — they emerge when the card is hovered.
   This keeps the header clean. Controls should never distract from content.)

Drag affordance:   The entire header bar is draggable. Cursor changes to `grab`/`grabbing`.
                   No explicit drag handle icon — the header IS the handle.
```

---

### 3.3 Content Area

```
Padding:           16dp all sides
                   (Tighter than typical 24dp defaults — the 480dp card is compact.
                    Components must breathe within their own internal margins.)

Layout grid:       8dp baseline grid for all component placement
                   4dp for fine-grained sub-component alignment (e.g., label to input)

Interactive element spacing:
  Between control groups:    16dp
  Between label and control:  6dp
  Between sibling controls:  10dp

Scrollable content:
  If content exceeds available height, a custom scrollbar appears:
  Width: 3dp, Color: edge-accent (#2A3A58), corner radius: 2dp
  On hover: color transitions to prism-cyan dim (#007880)
  No scrollbar track visible — thumb only
```

---

### 3.4 Card Shadow and Depth

Cards do not cast a flat drop shadow. They cast a **volumetric ambient shadow** that implies real elevation above the canvas. This is implemented as a layered shadow stack:

```
Layer 1 (ambient):
  offset: 0px, 4px
  blur:   20px
  spread: −2px
  color:  #000000, 60% opacity
  (The broad ambient shadow establishes elevation)

Layer 2 (contact):
  offset: 0px, 2px
  blur:   6px
  spread: 0px
  color:  #000000, 80% opacity
  (The tight contact shadow anchors the card to its perceived hover height)

Layer 3 (glow — active cards only):
  offset: 0px, 0px
  blur:   60px
  spread: −10px
  color:  prism-cyan base (#00F5FF), 12% opacity
  (Active cards emit a faint colored light downward onto the canvas.
   This should be barely visible — a whisper, not a beacon.)
```

**Stacking:** When cards overlap, the top card's ambient shadow falls on the card below — not on the canvas. This requires correct z-ordering in the compositor. The stacking visual reinforces that cards are physical objects on a shared surface.

---

### 3.5 Card Animation

**Appearance:**
```
Trigger:           User launches tool from rail
Animation:         Scale from 0.88 to 1.0 + opacity from 0% to 100%
Duration:          280ms
Easing:            Spring: stiffness 400, damping 28, mass 1.0
                   (Slight overshoot ~1.5% at peak, settles without bounce)
Transform origin:  Launcher icon position (card expands outward from its icon)
Blur on entry:     Start at blur(8px), clear to blur(0px) over first 120ms
```

**Dismissal:**
```
Trigger:           Close button click
Animation:         Scale from 1.0 to 0.92 + opacity from 100% to 0%
Duration:          180ms
Easing:            Cubic-bezier(0.4, 0, 1, 1) — ease-in only, no spring on exit
Transform origin:  Card center
```

**Drag:**
```
On grab:           Scale: 1.02 (card lifts slightly)
                   Shadow Layer 1 blur: 40px (shadow deepens as card lifts)
                   Duration: 80ms ease-out
On release:        Return to 1.0 scale + original shadow
                   Duration: 200ms spring (stiffness 500, damping 35)
                   (Slight settlement oscillation — card lands, not snaps)
```

**Resize (if resizable):**
```
Content area reflows on pointer-up, not during drag
During drag:       Show ghost outline of target size only
On release:        Content fades in at new size (80ms opacity fade)
```

---

## 4. Typography

### 4.1 Primary Typeface: Inter Variable

**Why Inter:** Inter was designed explicitly for screen interfaces at small sizes. Its optical metrics at 11–13dp (the dominant size range inside a 480dp card) are superior to alternatives. The variable font axis covers the weight range needed without separate files. Inter's uppercase figures and tabular numeral variant are essential for value displays that change numerically without layout shift.

**Weights in use:**

| Weight       | Value | Usage                                                      |
|--------------|-------|------------------------------------------------------------|
| Regular      | 400   | Body copy, dropdown options, tooltip text                  |
| Medium       | 500   | Labels, secondary headings, active states                  |
| SemiBold     | 600   | Card header tool name, primary control labels              |
| Bold         | 700   | Reserved for alert/error headings only — use sparingly     |

**Color treatment:** Body text is never pure white. Pure white text on dark backgrounds creates harsh contrast that reads as clinical, not premium. Use:

| Text Role             | Color Hex   | Opacity | Notes                                     |
|-----------------------|-------------|---------|-------------------------------------------|
| Primary text          | `#E2E8F0`   | 100%    | Main labels, values, headings             |
| Secondary text        | `#94A3B8`   | 100%    | Descriptions, hints, idle states          |
| Disabled / muted text | `#475569`   | 100%    | Inactive options, placeholder             |
| Accent text           | `#00F5FF`   | 100%    | Active values, selected state labels      |

---

### 4.2 Secondary Typeface: None

Inter handles all use cases. Adding a secondary display typeface to a dense tool UI creates inconsistency without benefit. If a future marketing context (splash screen, onboarding) requires a display face, evaluate then. For v1.0 of the tool suite: Inter only.

---

### 4.3 Type Scale (within 480dp card context)

All sizes in dp. Line heights in multipliers.

| Role                  | Size | Weight | Line Height | Letter Spacing | Usage                                    |
|-----------------------|------|--------|-------------|----------------|------------------------------------------|
| Card heading          | 13dp | 600    | 1.3         | +0.01em        | Tool name in header bar                  |
| Section label         | 11dp | 500    | 1.4         | +0.04em        | Group labels, section dividers           |
| Control label         | 11dp | 400    | 1.4         | +0.02em        | Slider labels, knob labels               |
| Value display         | 12dp | 500    | 1.2         | −0.01em        | Numeric readouts, current values         |
| Micro label           | 10dp | 400    | 1.4         | +0.05em        | Axis labels, tick marks, tooltips        |
| Status text           | 11dp | 400    | 1.4         | 0              | Info banners, inline status              |

**Optical corrections:** At 10–11dp, increase letter-spacing by +0.02–0.05em to compensate for hinting artifacts on non-retina displays. On 2× displays, default spacing is correct.

---

### 4.4 Monospace Usage: JetBrains Mono

For hex codes, coordinate pairs, curve handle values, MIDI note numbers, and any machine-readable value: **JetBrains Mono** at weight 400.

**Why JetBrains Mono over alternatives:** JetBrains Mono has generous x-height, open apertures that remain legible at 10dp, and tabular figures by default. Its ligature set (disabled in tool UI — `font-feature-settings: "liga" 0`) would create ambiguity in value strings.

```
Monospace usage spec:
  Font:             JetBrains Mono, weight 400
  Size:             11dp for inline values, 10dp for dense data tables
  Color:            #94A3B8 (secondary text) idle, #00F5FF (accent) when value is being edited
  Background:       Surface 2 (#161D2E) pill, 4dp corner radius, 4dp horizontal padding
                    (Values live in a subtle dark chip, separating them from label text)
  Ligatures:        Disabled ("liga" 0, "calt" 0)
  Tabular figures:  Enabled ("tnum" 1) — mandatory for values that update in real-time
```

---

## 5. Interactive Component Specs

### 5.1 Sliders

Prism has two slider variants. The decision between them is made by the tool designer based on the nature of the value being controlled.

**Variant A: Gradient-Filled Track (Color/Spectrum Sliders)**

Used when: the slider represents a value that is *visually meaningful across its range* — hue, saturation, brightness, temperature, opacity, gradient stop position.

```
Track height:      10dp
Track corner radius: 5dp (pill)
Track fill:        A CSS/UMG gradient matching the parameter's value range
                   (e.g., hue slider: full HSL spectrum, hsl(0,100%,50%) → hsl(360,100%,50%))
Track border:      1px, edge-subtle (#1F2B42), 30% opacity (recedes, shows gradient clearly)

Thumb:
  Shape:           Circle, 18dp diameter
  Fill:            Surface 3 (#1C2540)
  Border:          2px, white (#FFFFFF) at 90% opacity
  Glow:            0 0 8px [current track color at thumb position] at 60% opacity
  Active glow:     0 0 16px [current track color] at 85% opacity

Value display:
  Position:        Floating above thumb, appears on grab, disappears 600ms after release
  Format:          JetBrains Mono chip (see §4.4)
  Content:         Raw value with unit (e.g., "247°", "84%", "#1A8CFF")
```

**Variant B: Bare Track (Numeric Sliders)**

Used when: the slider represents a dimensionless or abstract numeric value — gain, attack time, mix percentage, opacity — where the gradient would be meaningless noise.

```
Track height:      4dp
Track corner radius: 2dp
Track fill (left of thumb):   prism-cyan dim (#007880)
Track fill (right of thumb):  edge-subtle (#1F2B42)
Track border:      None

Thumb:
  Shape:           Circle, 14dp diameter
  Fill:            #FFFFFF (white — clean contrast against dark canvas)
  Border:          None
  Glow:            0 0 6px prism-cyan base (#00F5FF) at 50% opacity on hover
  Active glow:     0 0 12px prism-cyan base at 80% opacity

Value display:     Same floating chip as Variant A
```

---

### 5.2 Color Swatches

```
Swatch size:       28 × 28dp (standard), 20 × 20dp (compact, in dense palettes)
Corner radius:     6dp (standard), 4dp (compact)
Spacing:           6dp between swatches in a grid, 4dp in compact

Border (default):  1px, edge-subtle (#1F2B42), 50% opacity
Border (hover):    1px, white at 40% opacity
Border (selected): 2px, white at 100% opacity + outer glow:
                   0 0 8px [swatch color] at 70% opacity

Selected state:
  Inner ring:      2dp inset from border, 1px white at 60% opacity
                   (Creates a double-ring effect: outer white border, inner white ring,
                    swatch color fills the center — immediately legible as selected)

Empty state:
  Fill:            Surface 2 (#161D2E)
  Pattern:         A fine checkerboard in edge-subtle tones (4dp squares)
                   (Indicates "no color" without using white/grey ambiguously)
  Border:          1px dashed, edge-accent (#2A3A58)
  On hover:        Border brightens to prism-cyan dim, cursor shows add-color affordance

Tooltip:
  Appears on hover after 400ms delay
  Shows hex value in JetBrains Mono chip + swatch color name if named
```

---

### 5.3 Knobs (Rotary Controls)

Knobs are the most physically evocative component in Prism. They must look and feel like real hardware rotary controls — not generic semicircle UI widgets.

```
Outer diameter:    44dp (standard knob)
                   32dp (compact, for parameter-dense cards)

Body:
  Material:        anodized-metal archetype — dark brushed circle
  Fill:            Radial gradient: #1C2540 center → #0D1117 edge
  Border:          1px, #2A3A58 at 80% opacity (subtle ring defining the knob body)
  Depth shadow:    inset 0 2px 4px rgba(0,0,0,0.8) (knob is recessed into its mount)

Indicator line:
  Width:           2dp
  Length:          12dp (extends from 60% radius to 90% radius — does not reach center)
  Color:           #FFFFFF at 90% opacity idle, prism-cyan base (#00F5FF) on focus
  Glow:            0 0 4px prism-cyan base at 60% opacity on focus

Travel range:      270° arc (−135° to +135° from 12-o'clock)
Zero position:     7 o'clock (bottom-left) for range knobs
                   12 o'clock (top) for pan/balance knobs
                   (Matches physical hardware convention)

Arc track:
  A 270° arc drawn under the knob at its edge
  Unfilled track:  edge-subtle (#1F2B42), 2dp stroke
  Filled track:    prism-cyan dim (#007880), 2dp stroke, covers from zero to current position
  Active track:    prism-cyan base (#00F5FF), 2dp stroke + 4px glow

Value display:
  Below knob, 4dp gap
  JetBrains Mono chip, 10dp size
  Appears on focus/hover, fades after 800ms of no interaction

Interaction:
  Primary: vertical drag (up = increase, down = decrease) — matches DAW convention
  Secondary: scroll wheel
  Precision: hold Shift for 10× slower resolution
  Double-click: opens numeric text input
```

---

### 5.4 Toggle Switches

```
Track size:        36 × 20dp
Corner radius:     10dp (pill)

OFF state:
  Track fill:      Surface 2 (#161D2E)
  Track border:    1px, edge-subtle (#1F2B42)
  Thumb fill:      #475569 (muted grey — visually suppressed)
  Thumb size:      16dp circle
  Thumb position:  Left, 2dp inset

ON state:
  Track fill:      prism-cyan dim (#007880) at 80% opacity
  Track border:    1px, prism-cyan base (#00F5FF) at 40% opacity
  Track glow:      0 0 8px prism-cyan base at 30% opacity (track glows softly when on)
  Thumb fill:      #FFFFFF
  Thumb position:  Right, 2dp inset
  Thumb glow:      0 0 6px prism-cyan base at 50% opacity

Transition:
  Duration:        160ms
  Easing:          Cubic-bezier(0.34, 1.56, 0.64, 1) — slight spring overshoot on thumb
  (The thumb doesn't slide mechanically — it snaps with a physical quality)

Label:
  Position:        Right of toggle, 8dp gap
  Style:           Control label (Inter 400, 11dp, #94A3B8 OFF, #E2E8F0 ON)
```

---

### 5.5 Dropdown Menus

```
Trigger element:
  Height:          30dp
  Padding:         0 10dp
  Fill:            Surface 2 (#161D2E)
  Border:          1px, edge-subtle (#1F2B42)
  Corner radius:   6dp
  Text:            Inter 400, 11dp, #E2E8F0
  Chevron icon:    8dp, #94A3B8, right-aligned with 10dp right margin
  Hover state:     Border brightens to edge-accent (#2A3A58)
  Focus state:     Border becomes prism-cyan dim (#007880), 1px focus ring outside border

Dropdown panel:
  Fill:            Surface 3 (#1C2540)
  Border:          1px, edge-accent (#2A3A58)
  Corner radius:   8dp
  Shadow:          0 8px 32px rgba(0,0,0,0.7) + 0 2px 8px rgba(0,0,0,0.5)
  Width:           Matches trigger width (minimum), expands if content is wider
  Max height:      240dp, scrollable beyond
  Padding:         4dp vertical, 0 horizontal

Option item:
  Height:          30dp
  Padding:         0 12dp
  Text:            Inter 400, 11dp, #E2E8F0
  Hover state:     Background: Surface 1 (#111622) tint overlay — NOT a full bg change
                   Text: #FFFFFF
                   Left border: 2dp, prism-cyan dim (#007880)
  Selected state:  Background: prism-cyan base at 10% opacity
                   Text: prism-cyan base (#00F5FF)
                   Left border: 2dp, prism-cyan base

Dividers:          1px, edge-subtle (#1F2B42), 0 horizontal margin

Open animation:
  Transform:       scaleY from 0.85 to 1.0, transform-origin top
  Opacity:         0% to 100%
  Duration:        140ms
  Easing:          Cubic-bezier(0, 0, 0.2, 1) — fast open, decelerates into place
```

---

## 6. Animation Principles

### 6.1 Core Philosophy

Animation in Prism follows one rule: **animate the physics of real objects, not the mechanics of UI transitions.** A card does not fade in. It materializes — assembling from its launch origin with physical momentum. A toggle does not switch states. It snaps like a physical switch and settles.

All timing follows a hierarchy: **feedback must be faster than perception (< 100ms), transitions must feel immediate but not jarring (100–300ms), and state changes must be readable (200–400ms).** Nothing takes longer than 400ms unless it is a deliberate reveal or loading sequence.

---

### 6.2 Card Entrance / Exit

*(Fully specified in §3.5 — repeated here for animation document completeness)*

**Entrance:** 280ms spring. Scale 0.88 → 1.0. Opacity 0% → 100%. Blur 8px → 0px. Origin: launcher icon position.

**Exit:** 180ms ease-in. Scale 1.0 → 0.92. Opacity 100% → 0%. No blur. Origin: card center.

**Key principle:** Entrances are springs; exits are ease-ins. Things arrive with life; they depart without ceremony. Slow exits feel like the UI is apologizing.

---

### 6.3 Value Changes

**Numeric values (counters, coordinates, percentages):**
Values do not snap to their new state — they tick. But they do not animate slowly like a slot machine. The tick is rapid: a value changing from 128 to 255 shows 3–4 intermediate frames in 60ms, giving the impression of motion without delay.

```
Intermediate frames: max(3, ceil(|delta| / 32))  — more frames for larger jumps
Total duration:      60ms (constant regardless of delta)
Each frame:          Opacity blink: 40ms at 100%, 20ms at 60%, repeat until final value
Final frame:         100% opacity, held
```

**Color values:**
When a color swatch or color readout changes, the old color cross-fades to the new. The transition is not a linear blend between colors (which creates an ugly muddy middle). It is an opacity cross-fade: the new color fades in at 100% opacity over the old, which fades out simultaneously.

```
Duration:            120ms
Easing:              Linear (opacity cross-fades look correct as linear; easing creates artifact)
```

---

### 6.4 Glow Pulse for Active State

When a tool is actively processing (rendering, computing, streaming data), its card and launcher icon enter a slow glow pulse. This is not an animation loop that plays regardless — it is tied to actual processing state.

```
Property:            Glow shadow intensity (the Layer 3 card shadow)
Range:               12% opacity → 22% opacity → 12% opacity (breathes)
Duration:            2400ms per cycle
Easing:              Cubic-bezier(0.37, 0, 0.63, 1) — smooth sinusoidal approximation
                     (This easing creates a sine-wave-like breath, not a linear pulse)
Color:               Follows active tool's category accent, not always prism-cyan

Launcher icon pulse:
  Same timing (synchronized with card)
  Icon rim light bloom: dim tier → base tier → dim tier
  The icon and card breathe together — they are the same object at different scales
```

**Rule:** The pulse only runs during verified processing. It stops the moment processing ends and settles to the static active-state glow within 400ms. Do not pulse for decorative or ambient reasons.

---

### 6.5 Wire Connections Between Cards

When tools are connected (output of one feeds input of another), a wire is drawn between them on the canvas layer beneath all cards.

**Wire visual:**
```
Line style:          Bézier curve (cubic), not straight line
                     Control point offset: 60% of card-to-card distance in the Y-axis
Stroke width:        2dp at rest, 3dp while data is flowing
Stroke color:        Source card's category accent color (base tier), at 60% opacity at rest
                     80% opacity while data is flowing

Animated flow:       When data is flowing, a moving highlight travels along the wire
  Highlight:         Radial glow point, 12dp spread, accent bloom tier, 80% opacity
  Speed:             400dp/s (appears to travel from source to destination continuously)
  Easing:            Linear (constant speed — implies steady data flow)

Wire terminus:       Where wire meets card border:
  Entry point dot:   6dp circle, accent color base tier, 100% opacity
  Glow:              0 0 8px accent color at 50%
```

**Connection animation:**
```
On connect:
  Wire draws from source card to destination
  Duration:          300ms
  Easing:            Cubic-bezier(0.0, 0.0, 0.2, 1) — wire shoots out and decelerates
  After wire arrives: entry point dot scales in (0 → 1) at 80ms spring
  Flow highlight begins immediately after wire fully extends

On disconnect:
  Wire retracts to source card
  Duration:          180ms ease-in
  Entry point dot fades (100% → 0%) simultaneously
  Glow extinguishes before wire finishes retracting (at 60% retraction progress)
```

---

### 6.6 Loading / Processing States

**Indeterminate loading (tool initializing, asset loading):**
```
Component:           A 2dp arc on a 20dp circle, inside the card's content area center
Arc length:          90° (quarter circle)
Rotation:            Continuous clockwise
Duration per cycle:  1200ms
Color:               prism-cyan base (#00F5FF), fading from 100% at leading edge to 0% at tail
Glow:                0 0 6px prism-cyan base at 40%, moves with the arc head
```

**Determinate progress (export, render, batch operation):**
```
Component:           A horizontal bar, full card width minus 32dp padding, 3dp height
Corner radius:       2dp
Track:               edge-subtle (#1F2B42)
Fill:                prism-cyan dim (#007880) → prism-cyan base (#00F5FF) gradient (left to right)
Glow:                0 0 8px prism-cyan base at 40%, only at the leading edge of fill

Progress percentage: JetBrains Mono chip, 11dp, centered above bar
```

**Completion flash:**
```
On operation complete:
  Bar fill:          Flashes to prism-lime base (#A8FF00) in 60ms
  Glow:              Expands to 0 0 20px prism-lime at 70%
  Hold:              200ms
  Fade out:          300ms to nothing (bar disappears, content loads in)
```

---

## 7. Dark Mode Only Policy

### 7.1 The Decision

Prism has no light mode. This is not an omission or a roadmap item — it is a deliberate design commitment baked into the visual identity at the foundation level.

### 7.2 The Aesthetic Reason

Prism's entire visual language is built on **additive light.** Color in Prism is emitted, not reflected. The glow of an active knob, the luminous rim on a 3D icon, the colored wire carrying data between cards — these are light sources. They work because the surrounding environment is dark enough to make them meaningful.

In a light-mode environment, all of this collapses. A cyan glow on a white background reads as a pale blue smudge. The 3D icons — designed with a dark world-space ambient — look flat and washed out. The elevation system (Surface 0 through Surface 3, differentiated by 3–7% lightness steps) becomes invisible. The entire depth hierarchy that makes Prism feel like a physical workspace evaporates.

Light mode would require a parallel visual identity — not a color-scheme inversion but a fundamentally different design philosophy. That parallel product does not exist. Prism is additive light on darkness. There is no version of that in a light environment.

### 7.3 The Practical Reason

Prism wraps Unreal Engine 5. The UE5 editor, the materials, the render outputs, the color-graded reference frames — all are calibrated for dark viewing environments. Professionals using Prism are also likely to be using: DaVinci Resolve (dark), Ableton Live (dark), Figma in dark mode, terminal emulators (dark). The ambient light of their workspace is calibrated for screen-accurate color evaluation, which means controlled, dim environments.

A light-mode Prism would be physically inappropriate for its users' working environment. Dark-only is not a stylistic preference; it matches the professional context.

### 7.4 What Dark-Only Enables

| Capability                          | Only Possible Because It's Dark-Only                                |
|-------------------------------------|---------------------------------------------------------------------|
| Additive glow system                | Glow is imperceptible on light backgrounds                          |
| 3D icon lighting                    | Icon lighting rig designed for dark ambient — cannot simply invert  |
| Elevation via shadow only           | Light-mode elevation requires background lightness changes          |
| Color-as-signal rule                | On white, muted colors read as styled; on black, they read as signal|
| Bloom / EEVEE post-processing look  | Bloom is an additive blend mode — requires dark ground to be visible|
| Consistent color evaluation         | Dark background is neutral for color work — white background biases perception |

### 7.5 Accessibility in Dark-Only

Dark-only does not mean inaccessible. All text passes **WCAG AA contrast** at minimum. Primary text (`#E2E8F0` on `#111622`) achieves a contrast ratio of **12.1:1**, exceeding AAA. Interactive elements at their idle state meet AA. Semantic colors (error, warning) meet AA for text use.

For users with photosensitivity: the glow pulse (§6.4) respects the `prefers-reduced-motion` media query — the pulse is replaced with a static glow indicator. All animations respect `prefers-reduced-motion`.

---

## Appendix A: Asset Naming Reference

```
[category]_[name]_[variant]_[size].[ext]

Icon renders:
  ui_icon_[category]_[toolname]_[state]_512.png
  States: idle | hover | active | selected

Environment/background:
  env_canvas_[variant]_[size].png

UI components:
  ui_btn_[type]_[state].png
  ui_slider_[variant]_[state].png
  ui_knob_[size]_[state].png
  ui_toggle_[state].png
  ui_swatch_[state].png
  ui_dropdown_[element]_[state].png

VFX/glow:
  vfx_glow_[color]_[size].png
  vfx_bloom_[intensity]_loop.png
  vfx_wire_[state]_[length].png
```

---

## Appendix B: Quick Reference — Critical Values

```
Canvas background:      #080A0E
Default card surface:   #111622
Card border:            #1F2B42
Primary accent:         #00F5FF (prism-cyan)
Primary text:           #E2E8F0
Secondary text:         #94A3B8

Card size:              480 × 480dp
Card corner radius:     16dp
Header height:          36dp
Content padding:        16dp

Icon canvas:            72 × 72dp
Icon safe zone:         48 × 48dp
Icon backing card:      64 × 64dp, radius 14dp

Primary typeface:       Inter Variable
Monospace typeface:     JetBrains Mono
Base type size (card):  11dp

Card entrance:          280ms spring (stiffness 400, damping 28)
Card exit:              180ms ease-in
Toggle transition:      160ms spring
Dropdown open:          140ms ease-out
```

---

*Prism Visual Identity System — v1.0*
*Maintained by Art Direction. All deviations require AD review and must be documented as exceptions, not precedents.*
