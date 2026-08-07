# Distributing via Homebrew

Homebrew is the most natural channel for this app's audience (local-AI /
developer users who already `brew install` everything), and as of 2026-08-07 it
is a committed channel rather than an option — see
[DISTRIBUTION.md](DISTRIBUTION.md). This documents how to ship the app as a
Homebrew **Cask**. Companion to
[APP_STORE_PUBLISHING.md](APP_STORE_PUBLISHING.md).

## Cask, not Formula

- **Formula** = CLI tools / libraries, usually built from source.
- **Cask** = a prebuilt GUI `.app` bundle. This app is a Cask.

Users run `brew install --cask <token>`. Homebrew downloads a prebuilt artifact
(a zip or dmg of the `.app`) from a URL — typically a GitHub Release — verifies
its SHA-256, and installs the `.app` to `/Applications`. `brew upgrade` updates
it; a `livecheck` rule lets Homebrew auto-detect new GitHub releases.

## Prerequisite: sign + notarize (needs the $99 program)

Homebrew does **not** bypass Gatekeeper. An unsigned or un-notarized `.app` gets
quarantined and blocked on launch, and Homebrew will not accept casks that
disable quarantine. So a clean `brew install --cask` requires **Developer ID
signing + notarization**, which needs the Apple Developer Program ($99/yr) — the
same membership as the App Store path. See the "Fallback: Developer ID direct
distribution" section of [APP_STORE_PUBLISHING.md](APP_STORE_PUBLISHING.md).

## Two paths in

### A. Your own tap (recommended to start)

A tap is just a GitHub repo named `homebrew-<name>` with a `Casks/` folder. Zero
gatekeeping, instant, fully yours — the normal path for new or niche apps.

```
brew tap bbirkinbine/tap
brew install --cask gpu-dock-history
# or in one shot:
brew install --cask bbirkinbine/tap/gpu-dock-history
```

Steps:
1. Create a GitHub repo `homebrew-tap` (the `homebrew-` prefix is required).
2. Add `Casks/gpu-dock-history.rb` (template below).
3. Publish a GitHub Release whose asset is the notarized, stapled, zipped `.app`.
4. Point the cask at that release asset URL and its SHA-256.

### B. The official `homebrew-cask` repo

`brew install --cask gpu-dock-history` with no tap — more discoverable. Submit a
PR to `Homebrew/homebrew-cask`. It must clear notability/quality bars
(`brew audit --new`); a brand-new niche app may not pass notability initially, so
most projects graduate to this after gaining some traction. Open vs closed source
does not matter for casks.

## The cask file (template)

`Casks/gpu-dock-history.rb`:

```ruby
cask "gpu-dock-history" do
  version "1.0.0"
  sha256 "REPLACE_WITH_SHA256_OF_THE_ZIP"

  url "https://github.com/bbirkinbine/dock-gpu-history/releases/download/v#{version}/GPU-Dock-History-#{version}.zip"
  name "GPU Dock History"
  desc "Live GPU utilization history in the Dock icon"
  homepage "https://github.com/bbirkinbine/dock-gpu-history"

  livecheck do
    url :url
    strategy :github_latest
  end

  depends_on macos: ">= :ventura"   # macOS 13+
  depends_on arch: :arm64           # Apple Silicon only

  app "GPU Dock History.app"

  caveats <<~EOS
    GPU Dock History is also on the Mac App Store. Installing both leaves two
    copies claiming the same bundle identifier; keep only one.
  EOS

  zap trash: [
    "~/Library/Containers/com.bbirkinbine.gpu-dock-history",
    "~/Library/Preferences/com.bbirkinbine.gpu-dock-history.plist",
  ]
end
```

Notes:
- Compute the checksum with `shasum -a 256 GPU-Dock-History-1.0.0.zip`.
- The `.app` must be notarized and stapled *before* zipping so Gatekeeper passes.
- `depends_on arch: :arm64` matches the Apple-Silicon-only build.
- `zap` cleans up the sandbox container and prefs on `brew uninstall --zap`.
- `livecheck` with `github_latest` lets `brew livecheck` detect new releases.
- The `caveats` block carries the store-copy warning because `conflicts_with`
  only arbitrates cask against cask — it cannot see a Mac App Store install.
  Two bundles with the same identifier make LaunchServices pick between them
  unpredictably, and launch-at-login registers per bundle via `SMAppService`.
  Drop the block if the store listing is ever abandoned.

## Release workflow (per version)

Full versioning scheme and the git-tag / GitHub-Release mechanics are in
[RELEASING.md](RELEASING.md); the cask-specific steps:

1. Bump `MARKETING_VERSION` / `CURRENT_PROJECT_VERSION` in `project.yml`.
2. Archive, Developer ID sign, notarize (`xcrun notarytool submit`), staple
   (`xcrun stapler staple "GPU Dock History.app"`).
3. Zip the app, preserving the bundle:
   `ditto -c -k --keepParent "GPU Dock History.app" GPU-Dock-History-<version>.zip`
4. Create a GitHub Release tagged `v<version>`; attach the zip.
5. Update the cask `version` + `sha256` (open a PR if on the official repo).

## Validate before publishing

```bash
brew audit --cask --new gpu-dock-history   # or --strict
brew style Casks/gpu-dock-history.rb
brew install --cask ./Casks/gpu-dock-history.rb   # local test install
```

## Relationship to the other channels

The App Store and Homebrew are not mutually exclusive — one Developer Program
membership covers Developer ID notarization (for Homebrew and direct download)
*and* App Store distribution. Many apps ship both, and this app is one of them.

The order is decided in [DISTRIBUTION.md](DISTRIBUTION.md): this channel and the
GitHub Release it points at go live **first**, because between them they need
only a Developer ID certificate, while the store additionally needs full Xcode,
a hosted privacy-policy URL, an App Store Connect record, screenshots, and a
review pass. For this app's audience Homebrew also plainly matters more than the
store — but it ships first because it is unblocked, not because it is preferred.
