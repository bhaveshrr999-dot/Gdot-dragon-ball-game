<!-- coderabbit-ai-generated:v1 -->

# Ultimate Warriors — development roadmap

<!-- coderabbit-ai-generated:v1 -->

<!-- coderabbit-ai-generated-section:v1:9782a3ec9c34e44af5eeee1f94014546fec4c548eb438b883b8cbceb97b0e1fe -->

## Historical baseline: 0.1.0

See [UPDATE_0_2.md](UPDATE_0_2.md) for the subsequent menu repair, Blender assets, animation blending, VFX, story and mode expansion. The sections below record the original baseline and its remaining objectives.

<!-- /coderabbit-ai-generated:v1 -->

This is the first playable implementation, not the finished game described in the master prompt. The repository began with only [the lore README](readme.md). Consult that reference for technique descriptions and continuity, and use this checklist to avoid confusing implemented systems with finished content. The user raised the source asset ceiling to 1.5 GB; never pad assets to fill it.

## Available in this build

- Godot 4.7.2, Compatibility renderer, modular GDScript components, resource attack definitions, signal-driven combat.
- Goku and Vegeta with original geometric placeholder models, costume colors and distinct hair silhouettes. Models are generated in code; there are no extracted game files.
- All 11 requested Goku form labels and 9 Vegeta form labels select live models, hair/aura colors and power/speed/ki statistics. Transformation pulses and poses are procedural. SSJ3 extends the hair. These are not 20 finished bespoke character rigs or animation sets.
- Goku: Kamehameha, Super Kamehameha, Kaioken Kamehameha, Spirit Bomb, Super Spirit Bomb, Instant Transmission, Dragon Fist (film/GT label), Warp Kamehameha and God Kamehameha. Ultra Instinct forms probabilistically evade and counter nearby melee. Final Kamehameha is not assigned to unfused Goku.
- Vegeta: Galick Gun, Final Flash, Big Bang Attack, Final Explosion (with self damage), Final Galick Gun, Gamma Burst Flash (manga label), Prominence Flash and Atomic Flash (game labels), and a clearly labeled fan-made Ultra Ego rush.
- Light/heavy chains, short input buffer, ki blasts, launched knockback, grapple, guard/perfect guard, movement/flight, teleport vanish, charge, ki costs, attack startup and recovery, swept projectile hits, interactive opposing beam clashes.
- Four AI difficulty settings; approach, attacks, guarding, charging, evasion and transformation decisions.
- Seven procedural arena layouts: wasteland, tournament, Namek, destroyed Namek, Time Chamber, city and alien battlefield. Breakable props and capped crater markers; these are not physics-driven destructible terrain.
- Versus, stationary-dummy training, three-wave labeled fan story, survival, 90-second time attack, and shared-keyboard local battle. Local battle is not network multiplayer or dual-device Android play.
- Main menu, fighter/form/arena/mode selection, health/ki HUD, hit counters, damage text, pause/rematch, audio/graphics settings and persistent custom touch positions.
- Multi-touch movement and actions, hold guard/charge, flight buttons. Touch layout editing currently requires actual touch input. Keyboard controls are shown in game and documented in BUILDING.md.
- Seven original synthesized sound effects and an original icon. No franchise music or voice recordings.
- Signed Android ARM64 APK, SHA-256 verification, source, export settings, automated logic tests and CI build configuration.

## Phase checklist and remaining work

1. **Architecture and playable build — implemented baseline.** Further separate projectile/clash logic, camera, HUD and AI from the main coordinator. Add pooling for effects and projectiles.
2. **Models, rigs and animations — unfinished.** Replace clearly disclosed geometric placeholders with distribution-permitted, accurate character models; add Skeleton3D, skin weights, facial expressions and authored clips. Current breathing uses AnimationPlayer and limbs use procedural posing; AnimationTree/skeletal blending is not implemented.
3. **Combat and signature moves — implemented baseline, refinement open.** Create authored startup/charge/impact/recovery animations and attack-specific cinematics. Improve AI, collision against scenery, dodge/rush complexity, combo branches and tuning. Most signature beams share the same geometric effect system.
4. **Transformations — functional baseline, visual content unfinished.** Form stats and colors work, but not every form has unique hair geometry, aura particles, a unique sound or a bespoke transformation animation. Add exact form/attack availability constraints and era-specific outfit variants. Ultra Ego currently uses a power multiplier and fan-made rush; its full damage-powered mechanic is unfinished.
5. **Arenas, audio, VFX and destruction — unfinished.** Replace procedural layouts with authored environments; add physical debris, collidable breakable terrain, atmosphere, music, audio mixing, richer particles and arena-specific sky/lighting. No third-party asset bundle has been acquired or claimed.
6. **Menus, modes and controls — implemented baseline, polish open.** Expand story content, unlock progression, training readouts, local controller support and Android local-play design. Improve responsive UI, safe areas, accessibility and hold/repeat behavior.
7. **Android performance and export — partially verified.** APK builds, signature, archive, ABI/ELF headers and alignment are checked. Actual ARM64 install/launch/gameplay, Mobile-vs-Compatibility benchmark, thermal/memory tests and 30/60 FPS targets remain unverified. No compatible device is attached, the x86_64 host has no /dev/kvm, and remote device access requires authentication. Do not treat desktop or web execution as Android evidence.
8. **QA and refinement — ongoing.** Logic suite has 116 passing assertions; native Mesa rendering is exercised. Desktop software rendering measured about 15 FPS on the initial balanced build, not a phone performance result. Audio playback through physical speakers and all touchscreen behavior on a phone remain unverified.
9. **Publishing — development distribution only.** Publish a GitHub prerelease and verify the uploaded bytes; reserve a finished release claim for validated Android gameplay and completed assets/content. CI produces debug-signed development artifacts, not production-signed releases. Preserve the private release key outside Git for update compatibility.

## Asset rules

See [asset-manifest.json](data/asset-manifest.json) and [LICENSE](LICENSE). Audio is original CC0 synthesis; original code is MIT. These licenses do not grant Dragon Ball franchise rights. Do not download ripped game models, animations, voices or music. Add each future third-party asset's exact source, license and byte count before including it.

## Highest priority next work

1. Install this prerelease on an ARM64 Android phone and capture launch/gameplay logs, touch input evidence, crashes, memory and sustained FPS.
2. Secure appropriate character model and animation assets and integrate real skeletal animation.
3. Benchmark both renderers on that device; reduce draw calls and introduce VFX/projectile pools, LOD and adaptive quality.
4. Finish individual form visuals and attack choreography; expand collisions, arena destruction and original story content.
