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

Also note App Review Guideline 4.2 (minimum functionality): single-purpose utilities do get approved, but a bare dock graph is thin. Adding a small preferences window (sample rate, bar color, menu bar mirror option) materially improves approval odds and the product.

## 1. Apple Developer Program

- Enroll at developer.apple.com/programs — $99/year, individual enrollment is fine.
- Needed for: signing certificates, App Store Connect access, TestFlight.

## 2. Project prerequisites (in this repo)

- [ ] `xcodegen generate` produces `GPUDockHistory.xcodeproj` from `project.yml`.
- [ ] Set `DEVELOPMENT_TEAM` in `project.yml` (your 10-char Team ID, from developer.apple.com → Membership).
- [ ] Bundle ID `com.bbirkinbine.gpu-dock-history` — register it at developer.apple.com → Identifiers, or let Xcode automatic signing do it.
- [ ] **App icon**: MAS requires a full `Assets.xcassets/AppIcon.appiconset` (1024×1024 master, all sizes). The dock tile replaces the icon at runtime, but the icon is still required for the store page, Finder, and review.
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

1. Scheme → destination "Any Mac (Apple Silicon, Intel)" — or set arm64-only if you prefer; MAS accepts Apple Silicon-only apps.
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
