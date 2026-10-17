# Arena nebula skybox

Six 1024 px faces for the arena's `WOV_Sky` (see `ArtPass.SkyFaces` in `../ArtPass.lua`).

- **Source:** the equirectangular panorama from "FREE - SkyBox Space Nebula" by paul_paul_paul, CC Attribution
  (https://sketchfab.com/3d-models/free-skybox-space-nebula-fa5c19c4f7cc4525a24b99425bd520c8). It is already
  credited in `Shared/Credits.lua`; keep that line if these faces ship.
- **Generated with** `python -I make_skybox.py <panorama> . void_nebula`, which reprojects the panorama and adds a
  procedural star layer.
- **Face convention** (checked in Studio with labelled test faces): Ft = -Z, Bk = +Z, Lf = +X, Rt = -X, none mirrored.
  On Up the image's top edge points to +X; on Dn it points to -X.
- **Uploaded 2026-10-16**; the ids are in `ArtPass.SkyFaces`. Roblox renders a skybox black at night, so
  ArtPass runs the arena at a daytime clock with the sun hidden.
