<!-- coderabbit-ai-generated:v1 -->

# Version 0.3.0 — animation, combat timing and form balance

This is the published iteration of an unfinished fan game. It retains the menu touch repair and the connected three-chapter rivalry/simulator campaign from 0.2. It does not claim production character art, a finished cinematic campaign or verified Android performance.

## Implemented refinement

- Original Blender Python API authoring now exports **34 clips per fighter** with a **27-bone rig**, including wrists, individual fingers, feet and eyes. Tailored torso/leg meshes, hand geometry, armor panels, mouth detailing and idle blinking replace or refine earlier simple geometry. Export source is `tools/create_blender_assets.py` (bpy5.2.3/Python3.13). No ripped models/animations were used.
- Motion covers idle, walk, run, sprint, flight, hover, ascend, descend, punch, hook, uppercut, medium, kick, grapple, guard, parry, charge, three transformation styles, beam charge, Final Flash charge, beam release, sphere charge/release, Ki blast, rush, vanish, dodge, hit, fall, landing, victory and defeat. Character lead hands and victory poses differ. Poses have anticipation, contact and recovery keys. Runtime AnimationTree blends them; duration matches recovery for short actions.
- Fixed backward-facing strike rotations identified in rendered contact sheets. Tests now check that hands/feet reach forward and that skeletal poses recover. Preserved short blink/impact keys by disabling the scene animation optimizer for each imported AnimationPlayer, based on the [Godot importer implementation](https://github.com/godotengine/godot/blob/4.7.2-stable/editor/import/3d/resource_importer_scene.cpp). The earlier optimizer removed the blink minimum.
- Goku has selectable base/raised/long skinned hair meshes; SSJ3 uses the long silhouette. Super Vegeta and Blue Evolution have broader proportions; God is slimmer. Iris colors change; SSJ3/Ultra Ego hide brows; Majin Vegeta enables a separate forehead mark. These are authored development representations, not finished likenesses.
- Melee now lands at 42% of recovery instead of instantly on button press. Range is checked at contact. Interruptions, guarding or vanishing cancel an unlanded hit. Three light hits use punch/hook/uppercut and the third launches. Confirmed hits can cancel the last0.15s of recovery into a selected special; whiffs or insufficient Ki cannot bypass recovery.
- Launch gravity, falling and landing reactions return knocked fighters to the ground; ground impacts create dust/craters. Pause and selection menus freeze the animation and combat clocks together. Round changes clear old attacks, projectiles and stun. Standalone Instant Transmission now teleports without damage, matching readme.md; Warp Kamehameha and rush attacks retain separate offense.
- Charge-up orbs, selected-form lightning, softer aura intensity, form descriptions/stat previews, delayed health damage trails, stamina display, actual discounted special costs, button fades/press feedback and action-duration cooldown rings. Positional combat audio uses a bounded six-voice pool and fires on gameplay events; physical audio playback has not been verified in the dummy-audio sandbox.

## Form balance

These are **normalized gameplay multipliers**, not canonical numerical power levels or claims of exact Fandom values. They preserve playable health ranges and differentiated costs. The README is the local lore reference. Automated Fandom requests returned403; no claim of fresh Fandom verification is made. Continuity labels remain visible, including separate Super manga/anime states and film/game techniques.

Base health remains200. Power scales melee/projectile damage; damage-received values below1 reduce incoming hits. Passive Ki recovery is1.5/s, so net idle Ki change is1.5 minus upkeep. Charging restores19/s. Kaioken strain cannot kill by itself. Returning to Base costs no Ki; other transformations cost ceil(10 +5×power). Exhaustion reverts to Base.

Blue specials cost85% of their listed base cost. Ultra Instinct evasion consumes8Ki and its chance halves below20Ki. Ultra Ego takes108% damage and gains fury from actual damage received: amount/200, capped at+50% power, decaying2.5 percentage points/s. It does not heal or grant immunity; switching forms clears fury. Projectiles retain their power at launch rather than gaining a later transformation bonus.

### Goku

| Form | Power | Speed | Ki upkeep/s | Damage received | Stamina/s | Evade | Health strain/s |
|---|---:|---:|---:|---:|---:|---:|---:|
| Base | 1.00× | 1.00× | 0.0 | 1.00× | 10.0 | 0% | 0.0 |
| Kaioken | 1.28× | 1.18× | 2.8 | 1.00× | 8.0 | 0% | 1.2 |
| Super Saiyan | 1.45× | 1.10× | 1.8 | 0.94× | 11.0 | 0% | 0.0 |
| Super Saiyan 2 | 1.70× | 1.18× | 2.7 | 0.91× | 11.0 | 0% | 0.0 |
| Super Saiyan 3 | 2.05× | 1.12× | 6.8 | 0.88× | 7.0 | 0% | 0.0 |
| Super Saiyan God | 2.20× | 1.24× | 1.5 | 0.85× | 14.0 | 0% | 0.0 |
| Super Saiyan Blue | 2.40× | 1.22× | 3.8 | 0.83× | 12.0 | 0% | 0.0 |
| Blue Kaioken | 2.75× | 1.38× | 7.5 | 0.86× | 7.0 | 0% | 2.0 |
| Ultra Instinct Sign | 2.55× | 1.34× | 4.8 | 0.90× | 13.0 | 22% | 0.0 |
| Mastered Ultra Instinct | 2.95× | 1.42× | 6.0 | 0.80× | 15.0 | 40% | 0.0 |
| True Ultra Instinct | 2.80× | 1.36× | 4.4 | 0.86× | 14.0 | 28% | 0.0 |

### Vegeta

| Form | Power | Speed | Ki upkeep/s | Damage received | Stamina/s | Evade | Health strain/s |
|---|---:|---:|---:|---:|---:|---:|---:|
| Base | 1.00× | 1.00× | 0.0 | 1.00× | 10.0 | 0% | 0.0 |
| Super Saiyan | 1.45× | 1.10× | 1.8 | 0.94× | 11.0 | 0% | 0.0 |
| Super Vegeta | 1.65× | 1.05× | 3.3 | 0.85× | 8.0 | 0% | 0.0 |
| Super Saiyan 2 | 1.70× | 1.18× | 2.7 | 0.91× | 11.0 | 0% | 0.0 |
| Majin Vegeta | 1.80× | 1.18× | 3.6 | 0.88× | 10.0 | 0% | 0.0 |
| Super Saiyan God | 2.20× | 1.24× | 1.5 | 0.85× | 14.0 | 0% | 0.0 |
| Super Saiyan Blue | 2.40× | 1.22× | 3.8 | 0.83× | 12.0 | 0% | 0.0 |
| Blue Evolution | 2.70× | 1.23× | 5.8 | 0.78× | 10.0 | 0% | 0.0 |
| Ultra Ego | 2.40× | 1.16× | 4.5 | 1.08× | 12.0 | 0% | 0.0 |

## Validation and limits

The project test script includes touch input/pause, combat, form effects, impact timing and animation-axis/blink regressions. Native rendering and endurance checks run on x86_64 Mesa software OpenGL; they do not establish Android frame rate, thermal behavior or compatibility. Release packaging checks verify ARM64 ELF libraries, archive integrity, signatures and16KB alignment. See the release notes for exact pass counts and APK checksum.

Outstanding: finished character likenesses/textures and facial acting; unique cinematic sequences for every form/ultimate; deeper attack-specific hitboxes, camera direction, air combos and environmental collision; stricter continuity-aware move restrictions; richer campaign progression/unlocks; original music; device profiling and renderer comparison. The added motions share reusable animation families, and every form does not yet have an independently choreographed cinematic. The complete requested500MB content library has not been produced or padded.
