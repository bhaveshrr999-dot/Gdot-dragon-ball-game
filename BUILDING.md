<!-- coderabbit-ai-generated:v1 -->

# Build and play Ultimate Warriors

<!-- coderabbit-ai-generated:v1 -->

<!-- coderabbit-ai-generated-section:v1:7f59d564839720366bd1baedbc395b7f22dd4358c40631df154774c52c2b4d3f -->

## Current version

v0.3.0 uses versionCode3 and the same signing key as prior GitHub prereleases. Install the release APK over the older release to preserve settings. J/H/K are light/medium/heavy strikes. Asset regeneration is optional: use Python3.13 with `bpy==5.2.3`, then run `python tools/create_blender_assets.py` and reimport in Godot.

## Toolchain

<!-- /coderabbit-ai-generated:v1 -->

- [Godot 4.7.2 stable](https://godotengine.org/download/archive/4.7.2-stable/) with exactly matching standard export templates. The latest stable release was checked against the official archive at development time.
- OpenJDK 17 (local build used Temurin 17.0.21+9).
- Android platform-tools, SDK platform 36 and build-tools 35.0.1 or a compatible newer stable build-tools release. The local template export succeeded with platform 35 installed and build-tools 35.0.1; its embedded Android template targets API 36. SDK platform 36 is recommended for reproducible future setup.
- Python 3 for static verification. No Godot plugins, Gradle downloads, external APIs or provider credentials are needed by the game.

The APK targets `arm64-v8a`, Android API 24 or newer, landscape, package `org.ultimatewarriors.fangame`. It uses no network permission. An OpenGL ES 3 capable device is required by the Compatibility renderer. Device compatibility remains untested.

## Editor and tests

Open `project.godot` in Godot 4.7.2 and press F6 on `scenes/main.tscn`, or F5 for the project.

```bash
export GODOT_BIN=/path/to/Godot_v4.7.2-stable_linux.x86_64
bash tools/build.sh test
bash tools/build.sh web
python3 -m http.server 8080 --directory build/web
```

The browser build requires WebGL2. The cloud Preview browser currently disables GPU rendering and does not expose WebGL2; its export succeeds but that environment cannot run it without a browser runtime configuration change. A native Godot/Mesa run was used to inspect real rendering separately.

## Android release signing

Install the standard Android export templates in Godot and set the Android SDK Path and Java SDK Path in Editor Settings. Keep a private release keystore outside this repository. Back it up securely: future updates require the same key. The development task's local key is stored privately in its runtime, not committed or uploaded.

Set `JAVA_HOME`, `ANDROID_HOME`, `GODOT_BIN`, and the following environment variables through your secret manager or local private environment, then build:

```bash
# Set these to your own private values. Do not commit them.
# GODOT_ANDROID_KEYSTORE_RELEASE_PATH
# GODOT_ANDROID_KEYSTORE_RELEASE_USER
# GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD
bash tools/build.sh android
```

The script exports a release APK, verifies its ZIP/ELF/ABI, validates its signature and 16 KB ZIP alignment, then writes SHA256SUMS under `build/android/`. Export alone is not runtime QA.

`.github/workflows/android.yml` imports the project, runs logic tests, exports a debug-signed ARM64 development APK and uploads an Actions artifact. Workflow execution must be checked on GitHub; configuration presence does not prove a successful CI run. CI debug artifacts use a different key from the GitHub prerelease APK and cannot replace an installed release-signed APK without uninstalling it.

## Installation from GitHub Releases

1. Download the APK and SHA256SUMS from the exact version's GitHub prerelease page, using your Android browser.
2. Compare the APK SHA-256 with the published checksum using a trusted checksum utility.
3. Allow installation from that browser/file manager when Android asks, then open the downloaded APK and install it.
4. Launch **Ultimate Warriors** in landscape. This APK is ARM64 only; it cannot install on a 32-bit-only device.
5. Installation, launch and gameplay on an ARM64 phone are not yet verified. If reporting a failure, include the phone model, Android version and any error text/logcat output. Do not disable platform protections to bypass an unexplained install error.

## Controls

- WASD: move relative to camera; Q/F: ascend/descend.
- J/K: punch/kick; G: grapple; L: ki blast.
- B: hold guard; C: hold charge; Space: vanish behind the rival.
- E: selected special; R: ultimate; T: transform into selected form (or next form if already selected).
- Enter or punch/kick: contribute during a beam clash; Esc: pause.
- Shared-keyboard Local Battle P2: arrow movement, numpad 1/2 strikes, 3 beam, 4 vanish, 0 guard, 5 charge. This mode is intended for desktop local keyboard play in this build.
- Android: left stick; right action buttons; hold Guard/Charge; arrow buttons control altitude. Change form and special with the HUD selectors. Settings → Move Touch Buttons enables dragging with touch.

All forms are selectable for testing. Some attacks require a minimum form index and sufficient ki; stricter era/form-specific restrictions remain on the roadmap. Base and transformed statistics are development tuning, not an asserted canon power ranking.

## Verification boundaries

The first build has automated combat/state/input checks, native desktop rendering evidence and static APK validation. No Android devices have been tested. ARM64 installability, graphics drivers, multi-touch comfort, 30/60 FPS performance, thermal behavior and memory stability remain open requirements in [DEVELOPMENT.md](DEVELOPMENT.md).
