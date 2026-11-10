<!-- coderabbit-ai-generated:v1 -->

# 0.2 development update

## Implemented and exercised

- Menu repair: restore touch-to-mouse emulation for Godot Controls; reject combat touches when the HUD is hidden or a modal is active; freeze combat while form/attack menus are open. Tests inject actual InputEventScreenTouch events through the engine, including selecting Kaioken and tapping pause/resume.
- Original Blender-generated skinned models for both fighters, 11 bones and twelve animation clips per rig, imported GLB scenes and AnimationTree state-machine transitions with 0.12-second blends. Clips: idle, run, flight, punch, kick, guard, charge, transform, beam, hit, victory, defeat. These are initial original development assets, not finished character art or a claim of AAA animation quality. Victory clips are exported but final victory presentation still needs integration.
- Blender-generated irregular rock meshes replace nearby conical rocks. The original generation script is tools/create_blender_assets.py. Regenerate with Blender's Python API package bpy==5.2.3 and Python 3.13. The OS Blender package download stalled; the bpy package installed and generated all assets successfully. No ripped models, animations or textures were downloaded.
- Animated rim/turbulence aura shader, bounded CPUParticles3D aura particles and projectile trails with an original radial sprite. These use the Compatibility renderer; bloom, screen distortion, lightning and attack-specific cinematic effects remain incomplete.
- Three connected fan-story chapters expand the existing rivalry-at-dawn/beyond-the-limits sparring premise into a malfunctioning training simulator scenario. Dialogue advances by touch, camera cuts frame fighters, battles resume after dialogue, and the ending saves campaign completion. This is original fan fiction; no prior detailed user storyline existed in the repository. Branching objectives, unlocks, facial animation and a long cinematic campaign remain unfinished.
- Tournament (three rounds), Arcade (five rounds), Boss Battle (Legendary, highest rival form), and a three-hit Combo Trial added alongside existing modes. These currently reuse Goku/Vegeta; they are initial implementations rather than broad rosters/brackets. Training reset restores resources and positions; Dummy toggles guarding.
- Medium strike (H or the new touch button) has intermediate damage and recovery; heavy attacks trigger a distinct kick pose/clip. Deeper directional combos, animation-event hit frames and cancellation remain open.

## Verification

124 combat/asset/state assertions and 17 input/story/mode assertions pass. Native Godot/Mesa rendering exercises the imported models, terrain and transformed aura. Desktop software rendering is about 15 FPS and is not evidence of Android performance. The screenshot supplied by the user shows the prior APK running on their phone with broken menu input; device model and Android version are unknown. We still have no connected ARM64 device for independent testing of this update.

## Outstanding final-build requirements

The full requested game is not complete. Production character proportions/costumes/face animation, all unique form geometry, individually authored transformation and ultimate sequences, accurate per-form attack restrictions, complete story unlock/progression content, additional mode depth, robust environmental collisions/destruction, original music/spatial sound, pooling/LOD, actual Android frame pacing/thermal/memory tests and renderer comparisons remain open. The small original asset set has not been padded toward 500 MB.

## Tool selection

Blender's GPL Python API was selected because it supports reproducible mesh, skin and action exports directly to GLB. Godot's AnimationTree, shader language and CPUParticles3D provide runtime blending and compatible VFX without plugins. Krita/GIMP/Pixelorama/LibreSprite are useful for hand-painted or pixel workflows but were not installed: this phase uses scripted 3D assets and a vector-generated particle sprite. Material Maker is deferred until authored environment materials need a texture graph. These choices avoid unnecessary GUI dependencies and subscription services.
