# Mac App Store approval — risk analysis

How likely this app is to be accepted on the Mac App Store, to inform the Apple
Developer Program ($99/yr) enrollment decision. Compiled 2026-07-18 from Apple
primary sources (App Review Guidelines, Apple Developer Technical Support forum
posts, Apple Developer News) and first-hand developer repositories.

**App Review Guidelines change often — re-verify the live text at submission
time.** Companion to [APP_STORE_PUBLISHING.md](APP_STORE_PUBLISHING.md).

## Bottom line

Approval is more likely than not — a reasoned estimate of roughly **65-75% on
first submission**, higher on resubmission because the likely rejection reasons
are fixable or appealable. None of the feared disqualifiers (AI-written code,
IOKit usage, the sandbox) actually block it.

The estimate is inferential: no approved Mac App Store precedent for this exact
category (a public-IOKit GPU dock-history monitor) was found, so treat the number
as considered judgement, not a measured base rate.

The $99 is a reasonable bet even if the Mac App Store rejects: the same
membership also enables Developer ID notarization for direct distribution (GitHub
release + Homebrew cask — see [HOMEBREW_DISTRIBUTION.md](HOMEBREW_DISTRIBUTION.md)),
the documented fallback.

## What is NOT a risk

### AI-written code
No App Store rule bans code written with AI assistance, and there is no
disclosure requirement for it. The only AI-specific rule in the current
guidelines is 5.1.2(i), which governs disclosing when an app shares personal
*data* with third-party AI at runtime — not how the code was authored. The 2026
"vibe coding" enforcement (Replit, Vibecode, "Anything") cited Guideline 2.5.2
(apps may not download/install/execute code that changes features at runtime);
Apple stated it "does not specifically target vibe coding apps" and that "the
issue was code execution capabilities, not AI authorship." A native Swift binary
that runs no generated code at runtime is outside 2.5.2 entirely.

### Public IOKit
Apple Developer Technical Support engineers state IOKit "is a public API and thus
can, in general, be used by Mac App Store apps," and that a comparable sandboxed
hardware-access approach "would not be an issue on the App Store" — with the
standard caveat that App Review has the final say.

### Sandbox
Verified locally that the App Sandbox does not block the IORegistry GPU read (see
[APP_STORE_PUBLISHING.md](APP_STORE_PUBLISHING.md) Section 0). Neutralized.

### The data path is standard
The `Device Utilization %` read from `IOAccelerator` / `AGXAccelerator`
`PerformanceStatistics` via public IOKit (no sudo, no private frameworks) is the
same approach used by multiple shipping tools (gpuer, gpuinfo, fastfetch, Stats).

## The real risks, ranked

### 1. Guideline 4.2 (minimum functionality) — most likely trigger, moderate
Apple rejects thin single-feature apps ("could have been a bookmark"). The
optional details/settings window is the standard mitigation and makes the app
present as more "app-like." A June 2026 (WWDC26) update tightened 4.2/4.3 with an
anti-copycat "do not add value" clause — re-check the live guideline at
submission, and lead with the window in screenshots and the description.

### 2. Guideline 2.5.1 (public-API-only) — real in policy, rarely enforced
Per Apple DTS, only IORegistry properties with a constant defined in the IOKit
headers count as "API"; others "would be grounds for your app to be rejected...
and, as such, is unsupported." `Device Utilization %` is an undocumented string
key with no SDK constant, so in policy it is technically rejectable. In practice,
Apple's automated tooling scans for private-framework linkage and private
symbols, not arbitrary string keys passed to the public
`IORegistryEntryCreateCFProperties` — so this is rarely detected, and no
first-hand case of a Mac App Store app rejected for this exact read was found.
Whether a human reviewer flags it is genuinely unknowable in advance.

### 3. Sandbox interaction — already neutralized
Verified not to block the read.

## Why comparable monitors are scarce on the Mac App Store

Not difficulty, not App Review friction, and not AI — the cause is private-API
limits. Full-featured monitors direct-distribute because their richer metrics
(temperature, power, frequency, per-process, fans, bandwidth) require IOReport
and SMC, which are incompatible with the App Sandbox the Mac App Store mandates.
First-hand:

- **SiliconScope:** "uses private (un-entitled) APIs (IOReport, SMC, HID), so it
  cannot be sandboxed/notarized for the App Store. Distribute directly."
- **MacMonitor:** "No App Sandbox — required to access Mach kernel APIs and
  IOReport. This means MacMonitor cannot be submitted to the Mac App Store."
- **Stats:** distributed via GitHub + Homebrew only; reads sensors beyond
  sandboxed IOKit.

These are polished, mature, open-source apps, so difficulty is not the barrier.
This app makes the opposite architectural choice — sandbox on, public utilization
only — which is precisely what keeps it eligible.

## Does the scarcity signal a high rejection rate?

A fair hypothesis (survivorship bias), but the evidence favors "never submitted"
over "submitted and rejected":

- The comparable apps are off the store by explicit, documented developer choice
  (private-API architecture), not by rejection.
- No rejection footprint: developers are vocal about rejections, and while 4.2
  rejection stories for other thin apps are common, none for a public-IOKit GPU
  monitor were found.
- The narrow sandbox-safe slice is simply under-built: free Stats already covers
  the function in the menu bar; the dock-tile form is niche; and it only recently
  became trivial to build.

Caveats that keep the hypothesis alive: no positive precedent (an approved GPU/CPU
monitor on the store doing this read) was found either, and quiet 4.2 rejections
can go unreported. So the scarcity is a mild negative signal, already reflected in
the estimate — not the strong signal it would be without the well-documented
private-API explanation. The decisive test is to find one approved system/GPU
monitor on the Mac App Store doing a similar public read; none surfaced in this
research (open item).

## Mitigations (to raise approval odds)

- Ship the details/settings window; lead with it in screenshots and the
  description (clears 4.2).
- App Review notes stating plainly: public IOKit only,
  `IORegistryEntryCreateCFProperties` over `IOAccelerator` `PerformanceStatistics`;
  no IOReport, SMC, or private frameworks; no IOKit user client; App Sandbox on.
  (Drafted in [STORE_LISTING.md](STORE_LISTING.md).)
- Keep Hardened Runtime + App Sandbox as configured.

## Open questions

- Would a human reviewer flag the undocumented `Device Utilization %` read under
  2.5.1, given it links no private framework and passes automated scanning? No
  precedent found.
- Does the June 2026 4.2/4.3 tightening apply here, and is the details window
  sufficient to clear the raised bar?
- Is any GPU or CPU dock/menu-bar utilization monitor already live on the Mac App
  Store as a direct approval precedent? None surfaced; a targeted store search
  would de-risk the estimate.

## Primary sources

- Apple Developer News, updated guidelines (2025-11-13): <https://developer.apple.com/news/?id=ey6d8onl>
- Apple DTS on IOKit + App Store (Quinn "The Eskimo!"): <https://developer.apple.com/forums/thread/51595>
- Apple DTS on sandboxed hardware access (2024): <https://developer.apple.com/forums/thread/768686>
- SiliconScope (private-API tradeoff): <https://github.com/kennss/SiliconScope>
- MacMonitor (no-sandbox rationale): <https://github.com/ryyansafar/MacMonitor>
- Stats: <https://github.com/exelban/stats>
- gpuer / gpuinfo (same public read): <https://github.com/simonw/gpuer>, <https://github.com/andersrennermalm/gpuinfo>
- Apple App Review Guidelines (live text): <https://developer.apple.com/app-store/review/guidelines>

## Method

Compiled via an automated multi-source research pass (fan-out web search across
five angles, 23 sources fetched, 25 extracted claims adversarially verified with
a 3-vote refutation threshold; 21 confirmed, 4 refuted). Findings resting on
Apple primary sources are high-confidence; the probability estimate and some 4.2
specifics are reasoned judgement corroborated by Apple statements. Re-verify
guideline text before submitting.
