# Publishing to the Mac App Store

What's required to take this repo from "builds locally" to "live on the Mac App Store." Steps are ordered. Fees/policies current as of mid-2026 — verify at [developer.apple.com](https://developer.apple.com) before acting on any of them.

## 0. Decide: App Store vs Developer ID (read this first)

Two distribution paths for a Mac app:

| | Mac App Store | Direct (Developer ID + notarization) |
|---|---|---|
| App Sandbox | **Required** | Optional |
| Review process | Yes, Apple review | No (automated notarization only) |
| Distribution | App Store page | Download from GitHub/your site |
| Cost | $99/yr Developer Program | Same $99/yr |

**The sandbox is the risk item for this app.** MAS requires `com.apple.security.app-sandbox`. Reading IORegistry properties (what `GPUSampler` does) is generally permitted under sandbox because it doesn't open an IOKit user client — but this must be **empirically verified** (build sandboxed, run, confirm the graph moves under GPU load) before assuming MAS is viable. If sandbox blocks the read, Developer ID direct distribution is the fallback — same repo, drop the sandbox entitlement, add notarization.

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

## 2. Project prerequisites (in this repo)

- [x] `xcodegen generate` produces `GPUDockHistory.xcodeproj` from `project.yml`.
- [ ] Set `DEVELOPMENT_TEAM` in `project.yml` (your 10-char Team ID, from developer.apple.com → Membership).
- [ ] Bundle ID `com.bbirkinbine.gpu-dock-history` — register it at developer.apple.com → Identifiers, or let Xcode automatic signing do it.
- [x] **App icon**: full `Assets.xcassets/AppIcon.appiconset` generated (all sizes incl. 1024 master) by `scripts/make-icon.swift` — a filled green GPU-history area chart in a modern macOS squircle tile, wired via `ASSETCATALOG_COMPILER_APPICON_NAME`/`CFBundleIconName`. Structure validated locally; the `actool`/`xcodebuild` compile is a CI gate (no local Xcode.app).
- [ ] Entitlements: `Resources/GPUDockHistory.entitlements` already has App Sandbox enabled. Hardened Runtime is on in `project.yml`.
- [ ] Verify sandboxed IOKit reads work (Section 0). Do this before anything else.

## 3. App Store Connect setup

At [appstoreconnect.apple.com](https://appstoreconnect.apple.com):

1. My Apps → **+ → New App** → platform macOS, name "GPU Dock History", your bundle ID, SKU (any unique string).
2. **Pricing**: free is simplest (no paid-apps agreement/banking/tax forms needed). Paid requires completing the Paid Applications agreement plus banking and tax info.
3. **App Privacy**: this app collects nothing and makes no network calls → privacy nutrition label is "Data Not Collected." You still need a **privacy policy URL** — a one-paragraph page ("collects no data, makes no network connections") hosted anywhere (GitHub Pages works).
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

## Fallback: Developer ID direct distribution

If MAS is rejected or sandbox blocks IOKit:

1. Remove `com.apple.security.app-sandbox` from the entitlements.
2. Archive → Distribute App → **Developer ID** → Upload for notarization (or `xcrun notarytool submit`).
3. Staple: `xcrun stapler staple "GPU Dock History.app"`.
4. Zip and publish as a GitHub release. Gatekeeper will accept it on any Mac.
