<p align="center">
  <img src="docs/media/banner.webp" alt="Horizon: the game you know, rebuilt in Rust" width="100%">
</p>

<p align="center">
  <a href="#installation"><b>Installation</b></a> ·
  <a href="https://github.com/SSIT2051/horizonCrack-but-it-works-/releases"><b>Releases</b></a> ·
  <a href="#project-status"><b>Project Status</b></a>
  <a href="#project-status"><img src="https://img.shields.io/badge/player--visible%20gaps-0%20open-F0795A" alt="Player-visible gaps open"></a>
</p>

# Horizon Launcher Fork

**Minecraft: Java Edition 26.3, rewritten in Rust (wgpu).** Your worlds, the same rules and terrain as vanilla, checked by hundreds of differential tests. One native program — no Java required. Free, open source (MIT), unofficial: you play with your own copy of Java Edition.

<p align="center">
  <img src="docs/media/readme/valley.webp" alt="A river valley with a plains village, savanna hills and a cherry grove, seen from above with a long view distance" width="100%">
</p>

> ⚠️ **Disclaimer:** This is an **unofficial fork** of the Horizon project. It is **not affiliated with, endorsed by, or associated with** the official Horizon launcher (playhorizon.dev), the Horizon Rust project, Mojang, or Microsoft. This is a community-maintained fork for personal use and experimentation.

## What is this fork?

This is a **customized fork of Horizon** — a complete rewrite of Minecraft: Java Edition in Rust, targeting version 26.3. It uses the same world format, same generation, same rules — but runs natively with better performance, lower memory, and no Java dependency.

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
curl -fsSL https://raw.githubusercontent.com/SSIT2051/horizonCrack-but-it-works-/main/packaging/linux/install.sh | bash
```

This downloads the latest installer script, which fetches and installs the newest launcher release (`launcher@X.Y.Z`), installs to `~/.local/bin/horizon-launcher`, adds a desktop entry, and works on glibc **and** musl (Alpine, Void, etc.).

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

## Project Status

**Player-visible gaps: 0 open** of the 833 the [port ledger](tools/port_ledger.py) found, reading every vanilla 26.3 method against Horizon's code: vanilla behaviour a player would notice that Horizon doesn't have yet. By area: Animals [0](https://github.com/horizon-rust/horizon/issues/3512), Monsters and bosses [0](https://github.com/horizon-rust/horizon/issues/3513), Entities, projectiles, vehicles and decorations [0](https://github.com/horizon-rust/horizon/issues/3514), Items, enchantments and inventories [0](https://github.com/horizon-rust/horizon/issues/3515), Blocks, redstone and fluids [0](https://github.com/horizon-rust/horizon/issues/3516), World, world generation and saves [0](https://github.com/horizon-rust/horizon/issues/3517), Screens, HUD and client packets [0](https://github.com/horizon-rust/horizon/issues/3518), Entity and block rendering, models [0](https://github.com/horizon-rust/horizon/issues/3519), Server and players on the server [0](https://github.com/horizon-rust/horizon/issues/3520), Mob AI, villagers and raids [0](https://github.com/horizon-rust/horizon/issues/3521). This number goes down as gaps close (`tools/parity_gaps.py`); the table below says what the harnesses compare.

### What the harnesses compare

Scores: 0 (absent), 0.25 (started), 0.5 (playable, major features missing), 0.75 (mostly complete) or 1 (its harnesses cover the subsystem and pass). Last audited 2026-10-13: the harnesses pass on Linux and macOS. The [port ledger](tools/port_ledger.py) adds a method-by-method view of what is ported.

| Subsystem | Score | Main gaps |
| --- | ---: | --- |
| Window, input and game loop | 1 | None: game loop, options, camera, auto-jump, toggle sprint/sneak and frame limiter match |
| Assets and resources | 1 | None: item models match over 196,290 stacks; the resource pack screen over 3,000 sessions |
| Network protocol and multiplayer | 1 | None: joins vanilla servers; the dedicated server matches vanilla's files, login, configuration, play and command tree; LAN discovery over 462 cases (offline mode only) |
| Chunk storage and palettes | 1 | None: client and saves share paletted containers, identical to vanilla over 266 scenarios |
| Section meshing | 1 | None: 112 scenes and over a million quads identical to vanilla |
| Rendering | 1 | None: entity models, block entity renderers (407 cases) and animations (296), HUD overlays (2,200 states), the recipe book (600), player list, subtitles and world border match |
| Lighting | 1 | None: saved and relit light matches vanilla, slabs and stairs included |
| World generation | 1 | None: 2,352 whole chunks over 225 structure sites, in all three dimensions, identical to vanilla |
| Region files and saves | 1 | None: saves round-trip with vanilla; worlds from 1.8 to 26.2 upgrade as vanilla's DataFixers do |
| Entities and physics | 1 | None: attributes, spawn rules, natural spawning (15,500 cases), raids and patrols (1,900), `finalizeSpawn` (24,000) and mob AI (92 scenarios) match |
| Interaction and inventory | 1 | None: menu clicks over 8,000 sequences; recipe book placement (6,000), buttons (1,200), saved book (1,500), loom and crafter screens (1,600) |
| Menus, HUD and chat | 1 | None: every command (758 over 39,685 inputs), scoreboards (81,000 operations), the player list (872,000 draw calls), chat and its suggestions (3,000 sessions) match |
| Audio | 1 | None: the sound engine, sound events, music, situational music, ambience and subtitles match vanilla |
| Block behaviours and ticking | 1 | None: block updates, random ticks, redstone, dispensers (6,000 cases), crafters (4,000), container spills (4,000), copper golems and the sculk family (435 scenarios) match |

## Licence

[MIT](LICENSE) for original work; deps keep their own ([notices](THIRD_PARTY_NOTICES.md)).  
Based on Horizon by [Ludovic Marie](https://lu4ovic.com) and [contributors](https://github.com/horizon-rust/horizon/graphs/contributors). This fork maintained by [SSIT2051](https://github.com/SSIT2051).

> **NOT AN OFFICIAL MINECRAFT PRODUCT.** Not approved by or associated with Mojang/Microsoft. Minecraft is a trademark of Mojang Synergies AB; its code/assets belong to Mojang/Microsoft under the [Minecraft EULA](https://www.minecraft.net/en-us/eula).
>
> **NOT AFFILIATED WITH THE OFFICIAL HORIZON PROJECT.** This is an unofficial community fork. The official Horizon launcher is at [playhorizon.dev](https://playhorizon.dev).