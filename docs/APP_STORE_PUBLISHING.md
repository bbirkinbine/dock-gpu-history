# Publishing to the Mac App Store

What's required to take this repo from "builds locally" to "live on the Mac App Store." Steps are ordered. Fees/policies current as of mid-2026 — verify at [developer.apple.com](https://developer.apple.com) before acting on any of them.

See also: [DISTRIBUTION.md](DISTRIBUTION.md) for which channels ship and in what order, [APP_STORE_APPROVAL_RESEARCH.md](APP_STORE_APPROVAL_RESEARCH.md) for an approval-likelihood risk analysis, [HOMEBREW_DISTRIBUTION.md](HOMEBREW_DISTRIBUTION.md) for shipping via Homebrew, [RELEASING.md](RELEASING.md) for versioning and how to cut a release.

## 0. The store is one channel of three (read this first)

Decided 2026-08-07, recorded in [DISTRIBUTION.md](DISTRIBUTION.md): this app ships through GitHub Releases, a Homebrew cask, **and** the Mac App Store — one sandboxed build, free in all three. Direct distribution is not a fallback here; it is the first channel to go live, and the store follows it. This document covers the store leg only.

| | Mac App Store | Direct (Developer ID + notarization) |
|---|---|---|
| App Sandbox | **Required** | Optional — kept on anyway, so both channels ship one build |
| Review process | Yes, Apple review | No (automated notarization only) |
| Distribution | App Store page | GitHub Release, consumed by the Homebrew cask |
| Cost | $99/yr Developer Program | Same $99/yr, same membership |

**The sandbox was the risk item for this app**, and it is settled. MAS requires `com.apple.security.app-sandbox`. Reading IORegistry properties (what `GPUSampler` does) is generally permitted under sandbox because it doesn't open an IOKit user client, but that had to be **empirically verified** rather than assumed — the verification is below. Had it failed, the store leg would have been dropped and the other two channels would have shipped an unsandboxed build.

> **Verified 2026-07-17 — the sandbox does NOT block the read.** A dev build
> ad-hoc-signed **with** `Resources/GPUDockHistory.entitlements` (app-sandbox on,
> genuinely enforced — a container was created at
> `~/Library/Containers/com.bbirkinbine.gpu-dock-history.dev`) returned live
> utilization under GPU load (`94 99 99 99 99 99`). The IORegistry
> `IOAccelerator` / `PerformanceStatistics` read works inside the sandbox, so the
> MAS path is viable. The sandbox's hardware rules depend on entitlements, not
> the signer, so a TestFlight/App-Store-signed build will behave the same; that
> remains the official final confirmation.

Also note App Review Guideline 4.2 (minimum functionality): single-purpose utilities do get approved, but a bare dock graph is thin. **Implemented:** an optional details/settings window (larger graph + time axis, GPU identity, memory-vs-budget gauge, peak/avg/time-at-100% since Reset, and settings for sample rate, graph color, and launch-at-login) now provides that functionality. It opens on first launch and from the Dock menu; the dock tile stays the primary product.

## 1. Apple Developer Program

- Enroll at developer.apple.com/programs — $99/year, individual enrollment is fine.
- Needed for: signing certificates, App Store Connect access, TestFlight.
- **Done** — membership active as of 2026-07-27, Team ID `G82L6VKCXZ`.

### Local toolchain prerequisite

Archiving requires **full Xcode.app**. Command Line Tools alone are not enough:
`xcodebuild` refuses to run against a CLT-only developer directory, so there is
no Archive, no automatic signing, and no upload. After installing Xcode from the
Mac App Store, point the toolchain at it and accept the license:

```bash
sudo xcode-select -s /Applications/Xcode.app
sudo xcodebuild -license accept
xcodebuild -version   # should print a version, not the CLT error
```

The dev build (`./scripts/build.sh`) and `scripts/verify.sh` only need `swiftc`,
which CLT provides — that is why this gap stayed invisible until store prep.

## 2. Project prerequisites (in this repo)

- [x] `xcodegen generate` produces `GPUDockHistory.xcodeproj` from `project.yml`.
- [x] Set `DEVELOPMENT_TEAM` in `project.yml` (your 10-char Team ID, from developer.apple.com → Membership). Set 2026-07-27, with `CODE_SIGN_STYLE: Automatic` so Xcode manages the App Store certificate and profile. CI is unaffected — it builds with `CODE_SIGNING_REQUIRED=NO`.
- [ ] Bundle ID `com.bbirkinbine.gpu-dock-history` — register it at developer.apple.com → Identifiers, or let Xcode automatic signing do it.
- [x] **App icon**: full `Assets.xcassets/AppIcon.appiconset` generated (all sizes incl. 1024 master) by `scripts/make-icon.swift` — a green GPU-history trace bleeding edge to edge in a modern macOS squircle tile, with a tracked-out "GPU" annotation top-left (skipped below 64px), wired via `ASSETCATALOG_COMPILER_APPICON_NAME`/`CFBundleIconName`. Structure validated locally; the `actool`/`xcodebuild` compile is covered by CI (and, since 2026-09-16, by a local Xcode 27 install).
- [ ] Entitlements: `Resources/GPUDockHistory.entitlements` already has App Sandbox enabled. Hardened Runtime is on in `project.yml`.
- [ ] Verify sandboxed IOKit reads work (Section 0). Do this before anything else.

## 3. App Store Connect setup

At [appstoreconnect.apple.com](https://appstoreconnect.apple.com):

1. My Apps → **+ → New App** → platform macOS, name "GPU Dock History", your bundle ID, SKU (any unique string).
2. **Pricing**: free is simplest (no paid-apps agreement/banking/tax forms needed). Paid requires completing the Paid Applications agreement plus banking and tax info.
3. **App Privacy**: this app collects nothing and makes no network calls → privacy nutrition label is "Data Not Collected." You still need a **privacy policy URL**. The policy is written — [privacy-policy.md](privacy-policy.md), which enumerates exactly what the app reads (GPU hardware properties, never personal data) and the four settings it stores locally. It needs hosting anywhere public; GitHub Pages serving from `/docs` gives the URL cited in [STORE_LISTING.md](STORE_LISTING.md).
4. **Metadata**: description, keywords, support URL (the GitHub repo is fine), category Utilities.
5. **Screenshots**: at least one macOS screenshot at a supported size (e.g. 2560×1600 or 2880×1800). Show the dock icon graphing under load — a screenshot of the dock during an Ollama/MLX run is the honest demo.

## 4. Archive and upload

In Xcode (from the generated project):

1. **Architecture — pin this deliberately.** The Mac App Store auto-derives hardware eligibility from the uploaded build; there is no manual "Apple Silicon only" toggle. It classifies on two things: the **deployment target** (`LSMinimumSystemVersion` 13.0 → the app is hidden from Macs on older macOS) and the **binary's architecture slices**. An **arm64-only** binary makes the store treat the app as Apple-Silicon-only and refuse to install it on Intel Macs — the slice *is* the declaration. A **universal** (arm64 + x86_64) binary is offered to Intel Macs too, where this app renders a flat graph (Intel integrated GPUs don't publish `Device Utilization %`) — a likely App Review 4.2 (minimum functionality) problem. What the store cannot see is the runtime GPU-key dependency, so architecture is the only lever that expresses "Apple Silicon only." For this app, ship **arm64-only**. `project.yml` pins `ARCHS: arm64`, so the generated project and any archive are Apple-Silicon-only by default — no per-archive action needed. If you ever want a universal build (e.g. to support AMD-discrete Intel Macs), remove that pin, but expect the 4.2 flat-graph problem on Intel integrated GPUs.
2. **Product → Archive**.
3. Organizer → Distribute App → **App Store Connect** → Upload. Xcode handles the App Store distribution certificate and provisioning profile with automatic signing.
4. Wait for processing in App Store Connect (minutes to an hour), then attach the build to your app version.

CLI alternative for CI: `xcodebuild archive` + `xcodebuild -exportArchive -exportOptionsPlist` with method `app-store`, then upload via `xcrun altool`/Transporter — not needed for a first manual submission.

## 5. TestFlight (optional but recommended)

Attach the build to TestFlight in App Store Connect and install it on your own machines. This catches sandbox/signing issues in the exact distribution-signed configuration before review.

## 6. Submit for review

- Add review notes explaining what the app does and that GPU stats come from public IOKit `IORegistryEntryCreateCFProperties` calls (preempts any private-API question — `IOAccelerator`/`PerformanceStatistics` are read via public API, but reviewers sometimes ask about anything IOKit-adjacent).
- First review typically takes 1–3 days. Rejections come with specific guideline citations; 4.2 (minimum functionality) is the likeliest for this app — see Section 0 mitigation.

## 7. Post-approval

- Releases: bump `MARKETING_VERSION`/`CURRENT_PROJECT_VERSION` in `project.yml`, re-archive, upload, submit update.
- Tag releases in git to match store versions.

## Developer ID direct distribution (ships regardless, and first)

Not a fallback — this is channel 1, and the store leg above depends on nothing here. See [DISTRIBUTION.md](DISTRIBUTION.md) for why this order.

1. **Keep** `com.apple.security.app-sandbox` in the entitlements. The sandbox does not block the read (Section 0), so both channels ship the same configuration and there is only one thing to test. Drop it only if a sandbox problem ever surfaces that the store leg would have to solve anyway.
2. Archive → Distribute App → **Developer ID** → Upload for notarization (or `xcrun notarytool submit`).
3. Staple: `xcrun stapler staple "GPU Dock History.app"`.
4. Zip and publish as a GitHub release. Gatekeeper will accept it on any Mac. This release artifact is also what the Homebrew cask points at — see [HOMEBREW_DISTRIBUTION.md](HOMEBREW_DISTRIBUTION.md).

Note that there is no in-app updater and will not be one — Sparkle is a third-party dependency, which the hard rules forbid. `brew upgrade` is the update path for this channel — but only for users who have run `brew trust bbirkinbine/tap`, since Homebrew 7 skips untrusted taps when enumerating outdated packages (see [HOMEBREW_DISTRIBUTION.md](HOMEBREW_DISTRIBUTION.md), "Tap trust"). A manually downloaded zip has none.
