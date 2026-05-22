# Vision

**Working name:** **Prism**
**Tagline:** *The studio in a window.*

---

## 1. Core Promise / Philosophy

**Thesis: "100x" means collapsing the tool-switching tax to zero.**

Today, shipping a single environment in Unreal involves a punishing relay race: Blender for the mesh, Substance for the materials, Photoshop for the decal, World Machine for the terrain, DAW for the audio sting, spreadsheets for the balance pass, and finally UE5 itself to wire it all together. Every handoff is a re-export, a re-import, a UV mismatch, a color profile drift, a broken reference. Studios estimate that 30–50% of a developer's day is spent *moving between tools*, not creating.

Prism's thesis is not "AI does it for you." It is: **every creative act a game needs — picking a color, painting a decal, tuning a curve, sketching a level, scoring a moment — happens inside one luminous surface that lives on top of Unreal Engine 5.** UE5 remains the runtime and the source of truth. Prism is the *creative cockpit* that wraps it: a constellation of beautifully focused micro-apps, each one as opinionated and pleasurable as Procreate's brush picker or Figma's color wheel, all sharing a single live scene state.

The 100x is not magic. It is the compound interest of removing friction from a thousand small decisions per day.

**And Prism is observable.** Even inside Unreal — the most powerful engine ever shipped to creators — you cannot see what your project is *doing*. Functions fire silently. Materials mutate behind a render pass. Curves drive a jump but the curve itself is buried six menus deep. The editor tells you what your project *is*. It refuses to tell you what your project *is doing*. That gap is where most debugging hours die.

Prism closes it. When a material parameter changes, every card subscribed to it pulses. When a function fires, the icon that called it ripples. When a curve drives a jump, the curve glows the instant the character leaves the ground. The canvas is a live readout of your project's interior state — not a static dashboard, an instrument. You stop guessing and start *seeing*.

## 2. Target User

**Primary: The "design-tool-pilled" solo dev and 2-5 person indie team** — creators who have the taste of a designer, the ambition of a studio, and zero patience for ugly enterprise software. They already pay for Figma, Procreate, Linear, and Arc. They believe the tools they use shape the work they make.

**Secondary: The "designer who can almost code"** — art directors, technical artists, and creative leads at mid-size studios who have ideas that currently require a programmer to realize. Prism's tools let them ship without that handoff.

**Tertiary: The most advanced.** AAA engine programmers, senior graphics engineers, technical directors who have stopped trusting the editor's visualizations and are tired of debugging by `UE_LOG`. Prism does not infantilize them. The Color Wheel a junior uses to pick a brick tone is the same Color Wheel a graphics engineer uses to diagnose a lighting bounce bug at 2am — because Prism makes engine state observable in ways the editor's panels never will. Advanced users get the same precision instruments; they just push them harder.

**Explicitly NOT for:** hobbyists looking for a free Roblox-style sandbox. Prism is prosumer software at a prosumer price point. It costs money. It expects taste.

## 3. Product Personality

**Anchor: The Linear of game development. The Procreate of 3D tools. The Pro Tools of UE5.**

Prism's personality is **confident, quiet, and luminous**. It does not shout. It does not gamify itself with achievement popups. It does not have a friendly cartoon assistant. It assumes you are a professional and treats your screen real estate as sacred.

Visually: deep black canvases, panels that feel weightless and floating, neon-saturated gradients reserved for *meaningful* moments (the color you just picked, the curve you just tuned, the asset that just finished baking). Glow is earned, never decorative. Every interactive element has the satisfying tactile inevitability of a hardware synthesizer knob.

Voice: terse, precise, slightly nocturnal. Error messages read like a senior engineer's Slack DM, not a Microsoft dialog. Onboarding is a single screen, not a tour. Documentation reads like Stripe's, not Unreal's.

**Prism brings back precision.** The industry traded visual craft for procedural plumbing — node graphs nobody can read, particle systems nobody can tune, color pickers that ship with three sliders and no math behind them. The result is a generation of game tools where everything is *adjustable* and nothing is *measurable*. Prism's tools are precision instruments first, aesthetic objects second: every value is numeric and addressable, every gradient is sampled at real coordinates, every curve has an equation under the glow. The luminous surface is not decoration. It is the readout of an instrument that respects you — the way a Moog respects a musician and a Leica respects a photographer. Visual art and numerical precision are not opposites. Prism is the proof.

## 4. Signature Moments

**The Palette Pull.**
You tap the Color app. A 3D rainbow wheel rises from the canvas, ringed in glow. With one gesture you sample the dominant hues of the current level — they materialize as floating swatches beside the wheel. You drag one swatch onto a building's material slot; every brick in the district shifts in real time across the live UE5 viewport, lit correctly, casting new GI bounce. No compile. No reimport. The swatch stays pinned to your canvas, ready for the next surface.

**The Decal Brush.**
You open the Paint app. A square card slides up showing a curated grid of grime, moss, blood, and graffiti decals — each rendered as a glowing 3D preview, not a flat thumbnail. You pick "rust-heavy," scrub your finger across a metal pillar, and the decal wraps the geometry with proper UV projection, depth-aware blending, and parallax. Pressure controls weathering intensity. Two-finger pinch changes scale. The result is bakeable to the mesh with one tap, or left as a runtime decal for performance.

**The Curve.**
You're tuning a jump. You open the Feel app. The character's velocity-over-time curve appears as a luminous neon line on a dark grid, with the actual physics simulation ghosting behind it. You bend the curve with your finger — the character in the viewport jumps again, and again, and again, replaying the motion every time you move a control point. There is no "apply" button. The curve *is* the jump. When it feels right, you swipe it into the Library; now every character in the game inherits the same arc, or you can fork it per-actor with one tap.

**The Trace.**
A character took fatal damage in a way that didn't make sense. In any other workflow you'd sprinkle log statements, recompile, replay the encounter, and pray. In Prism you tap the health value on the Inspect card. The canvas dims. A sequence of icons lights up in chronological order — every system that touched that value in the last two seconds, threaded with luminous wires in the exact call order, each node carrying the value it contributed. The rogue modifier glows brighter because it fired twice when it should have fired once. You drag the wire upstream to its source. You fix it. You never opened a log file. The bug was not hunted — it was *seen*.

---

## Closing

Prism is not trying to replace Unreal. It is trying to make Unreal feel like the year is 2026 instead of 2006. The bet is simple: **the next generation of great indie games will be made by people who refuse to use ugly software.** Prism is the tool they have been waiting for.
