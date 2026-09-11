# TryOnLoader

A looping loading screen for virtual try-on: a subject in the centre, ambient dots
orbiting it, and two garment tiles circling on a tilted orbit. Everything is driven
by one clock and every particle parameter is exposed live.

## Running it

Open `TryOnLoader.xcodeproj`, pick an iPhone simulator, run. The stage loops
forever — the copy cycles through three steps over `cycleDuration` (15s by
default) and starts again.

Tap the **sliders button** (top left) for the tuner. The sheet allows background
interaction at its small detent, so the animation keeps running while you drag.
`Copy settings as Swift` puts the current values on the clipboard as assignment
statements you can paste straight into `ParticleSettings`.

## Presets

`Save current settings` in the Presets section names and stores the whole
configuration; saving under a name that already exists overwrites it. Saved
presets apply wholesale (framing included) and swipe to delete. The four built-in
presets — Mockup, Dust, Calm, Energetic — only change the particles, leaving the
subject framing and loop duration you dialled in alone.

Presets live in `UserDefaults` via `PresetStore`, which also remembers the
settings you were last working on and restores them on the next launch.

## Artwork

`Assets.xcassets` holds three cutouts: `model` for the centre, `top` and `bottom`
for the garment tiles. Replacing any of them is just a matter of dropping a new
image into that image set. Transparent PNGs work best — the halo and the tile
background show through — and the garment images should be trimmed to the
artwork, since **Tile inset** adds the padding on top of whatever margin the file
already carries. If `top` or `bottom` goes missing the tiles fall back to a drawn
tee and leggings.

Frame a new subject with **Subject scale** (height as a multiple of the halo) and
**Subject offset** (how far down it sits inside the circle). The defaults frame a
full-body cutout from the head to mid-thigh.

## How it works

- `ParticleSettings` — a value type holding every knob, plus four presets.
- `ParticleField` — a `Canvas` inside `TimelineView(.animation)`. Each dot's
  position, size and alpha are a pure function of `(index, time)` via a hash, so
  there is no simulation state: changing a control never resets the field, and
  the dot count can change mid-flight. Alpha is quantised into 16 buckets so the
  canvas issues ~16 fills a frame instead of one per particle.
- `TryOnLoadingView` — owns the clock (including pause/restart) and composes the
  field, the halo, and the orbiting tiles. Tiles always draw over the subject;
  their position in the orbit only drives scale and shadow, never z-order.
- Reduced motion: when the system asks for it, `motionReduced()` slows the orbits,
  drops the pulse, and stops the wobble.

## Parameters worth knowing

| Control | What it does |
| --- | --- |
| Distribution | `spiral` uses a golden-angle layout (the halftone look), `ring` is a random band, `scatter` is area-uniform |
| Clumping | Biases dots toward the inner edge of the band |
| Swirl | Differential rotation — inner dots outrun outer ones |
| Outer fade | Fades dots toward the outer edge so the band has no hard boundary |
| Pulse | A wave that rolls out from the subject, brightening and enlarging dots as it passes |
| Orbit radius / width | Vertical radius, then the horizontal radius as a fraction of it. Below 1.0 the orbit is narrower than it is tall, which is what keeps a full revolution on screen beside a halo this wide |
| Depth scale | How much bigger a tile gets at the front of the orbit |

## Known limits

`ParticleSettings` uses synthesised `Codable`, so adding a property invalidates
presets saved by an earlier build — they fail to decode and are dropped rather
than migrated. Add `decodeIfPresent` defaults if presets need to outlive schema
changes.
