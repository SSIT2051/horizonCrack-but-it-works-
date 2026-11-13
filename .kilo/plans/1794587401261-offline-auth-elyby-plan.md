# Offline Auth + Ely.by Authentication Plan

## Goal
Enable playing Horizon without a Microsoft account by adding:
1. **Offline mode** - Play singleplayer and join cracked (offline-mode) servers
2. **Ely.by authentication** - Second auth provider alongside Microsoft
3. **Offline by default** - Microsoft login optional in settings

---

## Architecture Overview

### Current Flow (Microsoft only)
```
Launcher → Microsoft OAuth → Xbox Live → XSTS → Minecraft Services → Owner Gate → Session File → Game
```

### New Flow (Multiple Auth Providers)
```
Launcher → [Microsoft OAuth | Ely.by OAuth | Offline] → Auth Provider → Session File → Game
```

---

## Changes Required

### 1. Launcher: Account System (`launcher/src/account.rs`)

#### New Account Types
- Add `AuthProvider` enum: `Microsoft`, `ElyBy`, `Offline`
- Extend `Account` struct with `provider: AuthProvider`
- Extend `Secrets` with provider-specific fields

#### Microsoft (existing)
- Keep current flow unchanged
- Owner gate: check `entitlements/mcstore`

#### Ely.by (new)
- OAuth2 flow: `https://account.ely.by/api/oauth2/v1/authorize`
- Token endpoint: `https://account.ely.by/api/oauth2/v1/token`
- User info: `https://account.ely.by/api/account/v1/info`
- Minecraft auth: `https://authserver.ely.by/auth/authenticate`
- Owner gate: Check if account has Minecraft profile via Ely.by API

#### Offline (new)
- No network calls
- Generate offline UUID from username (Mojang algorithm: `UUID.nameUUIDFromBytes(("OfflinePlayer:" + name).getBytes())`)
- No owner gate - always allowed
- Session file with `user_type: "offline"`, `access_token: "0"`

#### Modified Functions
- `launch()` / `launch_for_game()` - Accept offline/Ely.by accounts
- `finish_sign_in()` - Handle Ely.by flow
- `session_for_game()` - Create session for offline/Ely.by accounts
- `write_session_file()` - Write correct `user_type` per provider

---

### 2. Launcher: UI (`launcher/src/main.rs`, `glass_account.rs`, etc.)

#### Account Management
- Add "Add Offline Account" button
- Add "Sign in with Ely.by" button (OAuth2)
- Show provider badge on each account
- Settings: "Default auth provider" dropdown (Offline / Microsoft / Ely.by)

#### Owner Gate Screen
- Show when no Microsoft/Ely.by account owns game
- Offer: "Play Offline" / "Sign in with Microsoft" / "Sign in with Ely.by"

---

### 3. Game Client: Auth Module (`crates/horizon-client-render/src/auth.rs`)

#### AuthSession Parsing
```rust
// Accept multiple user_type values
match field("user_type") {
    Some("msa") | Some("elyby") | Some("offline") | Some("legacy") => {},
    Some(other) => return Err(format!("unsupported user_type: {other}")),
    None => return Err("missing user_type"),
}
```

#### Offline UUID Generation
- Use `horizon_protocol::crypto::offline_uuid(name)` (already exists)
- Accept `access_token: "0"` for offline

#### Ely.by Session Support
- Same as Microsoft but with `user_type: "elyby"`
- Access token from Ely.by auth
- Profile UUID from Ely.by API

---

### 4. Game Client: Launch Options (`crates/horizon-client/src/game/launch_options.rs`)

#### Offline Mode Arguments
Already supported via:
- `--name` - player name
- `--uuid` - offline UUID
- `--accessToken 0`
- `--offlineDeveloperMode` (not strictly needed)

#### Session File Reading
- Accept `user_type: "offline"`, `"elyby"`, `"legacy"`
- Parse accordingly

---

### 5. Game Client: Network (`crates/horizon-client/src/net.rs`)

#### Server Join
- For online-mode servers: Use session service (Microsoft/Ely.by)
- For offline-mode servers: Skip session service, use offline auth
- Detect server mode from handshake

---

### 6. Ely.by Integration Details

#### OAuth2 Flow
1. Redirect to `https://account.ely.by/api/oauth2/v1/authorize?client_id=...&redirect_uri=...&scope=account_info minecraft_server_session offline_access&response_type=code&state=...`
2. Receive code at redirect URI
3. Exchange at `https://account.ely.by/api/oauth2/v1/token`
4. Get user info at `https://account.ely.by/api/account/v1/info`
5. Get Minecraft session at `https://authserver.ely.by/auth/authenticate`

#### Required Scopes
- `account_info` - Get username, UUID
- `minecraft_server_session` - Use as Minecraft session
- `offline_access` - Get refresh token

#### Client Registration
- Need to register Horizon as OAuth client on Ely.by
- Store client_id/secret in launcher config

---

## Implementation Order

### Phase 1: Offline Mode (Core)
1. Add `AuthProvider` enum to account types
2. Implement offline account creation
3. Modify owner gate to allow offline
4. Create offline session files
5. Update game auth to accept offline sessions

### Phase 2: Ely.by Authentication
1. Add Ely.by OAuth2 flow in launcher
2. Add Ely.by API client
3. Implement Ely.by session creation
4. Update game auth to accept Ely.by sessions

### Phase 3: UI & Polish
1. Add account provider selection UI
2. Add "Play Offline" button on owner gate
3. Settings for default auth provider
4. Translation keys for new strings

---

## Testing Strategy

### Offline Mode
- Create offline account, play singleplayer
- Join offline-mode server
- Verify offline UUID consistency

### Ely.by Mode
- Sign in with Ely.by test account
- Play singleplayer
- Join online-mode server (via Ely.by session service)
- Verify skin/cape loading

### Microsoft Mode (Regression)
- Existing Microsoft accounts still work
- Owner gate still enforces ownership
- Session renewal works

---

## Files to Modify

### Launcher
- `launcher/src/account.rs` - Core auth logic
- `launcher/src/account/session.rs` - Session handling
- `launcher/src/main.rs` - UI integration
- `launcher/src/glass_account.rs` - Account management UI
- `launcher/src/owner_page.rs` - Owner gate screen

### Game Client
- `crates/horizon-client-render/src/auth.rs` - AuthSession parsing
- `crates/horizon-client/src/game/launch_options.rs` - Session file reading
- `crates/horizon-client/src/net.rs` - Server join logic

---

## Risks & Mitigations

| Risk | Mitigation |
|------|------------|
| Ely.by API changes | Use documented endpoints, handle errors gracefully |
| Offline UUID conflicts | Use Mojang's `OfflinePlayer:` algorithm |
| Session file format | Keep backward compatible with `msa` |
| Server compatibility | Test with both online/offline mode servers |

---

## Open Questions

1. **Ely.by client registration**: Need to register Horizon on Ely.by to get client_id/secret
2. **Skin system**: Ely.by has its own skin system - integrate or use Mojang's?
3. **Migration**: How to handle existing Microsoft accounts? (Keep as-is)
4. **Default provider**: What should be the default for new users? (Offline per requirements)