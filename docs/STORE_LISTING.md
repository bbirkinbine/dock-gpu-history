# App Store listing — draft copy

Paste-ready metadata for App Store Connect (see docs/APP_STORE_PUBLISHING.md
Section 3). Character limits noted per field are Apple's. Fill the `<...>`
placeholders (URLs) once the repo/Pages are live. Nothing here commits you to
anything — it is copy staged for review.

---

## Identity

- **Name** (30 chars max): `GPU Dock History`
- **Subtitle** (30 chars max): `Live GPU graph in your Dock`
- **Primary category**: Utilities
- **Secondary category**: Developer Tools _(optional; fits the Ollama/MLX audience)_
- **Bundle ID**: `com.bbirkinbine.gpu-dock-history`
- **SKU**: `gpu-dock-history-1` _(any unique string; not shown to users)_

## Pricing

- Free _(no Paid Applications agreement / banking / tax forms needed)_

## URLs

- **Support URL**: `<https://github.com/bbirkinbine/dock-gpu-history>` _(repo is fine)_
- **Marketing URL** (optional): same as support, or leave blank
- **Privacy Policy URL**: `<https://bbirkinbine.github.io/dock-gpu-history/privacy-policy>`
  — from `docs/privacy-policy.md` once GitHub Pages is enabled (see note below)

## Developer identity, support, and repo model

### Enrollment type sets the public developer name

The Apple Developer Program enrollment type determines what the store page shows
as the developer, and it is publicly visible:

- **Individual / sole proprietor** ($99, no paperwork): publishes under your
  **legal name** (e.g. "Brian Birkinbine"). Simple; but your real name is public.
- **Organization** ($99, but needs a **D-U-N-S number** + a legal entity such as
  an LLC): publishes under a **company/brand name**, keeping your personal name
  off the page.

To publish under a brand rather than your name, enroll as an organization.
Switching individual -> organization later is possible but non-trivial.

**EU trader status (verify at enrollment):** under the EU DSA, apps classified as
commercial ("trader") must provide and **publicly display** contact details
(address / email / phone) on EU storefronts. A free, non-commercial app can
usually declare **non-trader**; confirm the current requirement in App Store
Connect, as it has evolved recently.

### Store-page URL fields (map GitHub to these)

| Field | Required | Shows on page as | Value for this app |
|---|---|---|---|
| Support URL | Yes | "App Support" | `https://github.com/bbirkinbine/dock-gpu-history/issues` |
| Marketing URL | No | "Developer Website" | repo root, or a GitHub Pages site |
| Privacy Policy URL | Yes | privacy link | Pages-hosted `docs/privacy-policy.md` |

The developer name also links to an auto-generated developer page listing all
your apps. There is no dedicated "GitHub" field, but Support/Marketing URLs make
the repo link appear.

### Repo / support model

This repo is **open source**, so one repo fills every role — no separate
"support-only" repo is needed:

- **Source** lives here.
- **Issues** are the Support URL (public bug tracker / feature requests).
- **Releases** host the notarized `.app` for Homebrew / direct download
  (see [RELEASING.md](RELEASING.md), [HOMEBREW_DISTRIBUTION.md](HOMEBREW_DISTRIBUTION.md)).
- The **App Store is a parallel channel** — the same app, listed for discovery
  and auto-update.

A separate public "issues-only" repo (README + changelog + Issues, no source) is
the pattern only for **closed-source** apps. Not recommended here: it is a free,
niche utility (low clone incentive) and the app name/icon are protected by
trademark regardless, so closing the source mostly adds overhead. If resale
deterrence is ever wanted, a **source-available license** on this same repo is
the middle path — keeps the single-repo simplicity.

Whether a binary appears in GitHub Releases is an independent choice: attach the
notarized `.app` when distributing via Homebrew / direct download; an
App-Store-only distribution would not need a binary on GitHub.

## Description (4000 chars max)

```
GPU Dock History turns your Dock icon into a live GPU utilization graph — a
scrolling history of how hard your Mac's GPU is working, right where you can
always see it.

Inspired by Activity Monitor's CPU history icon, but focused on the GPU. If
you run local AI models, render, game, or do anything GPU-heavy, you get an
at-a-glance readout without keeping a window open.

- Live GPU utilization history, updated continuously
- Lives entirely in the Dock — no window, no menu bar clutter
- Negligible CPU use when idle
- Reads GPU stats through Apple's public system APIs
- No data collection, no network access, no account

Built for Apple Silicon Macs (M1 and later).
```

## Promotional text (170 chars max, editable without a new build)

```
Your Dock icon, now a live GPU utilization graph. Watch your GPU work in real
time while you run local AI, render, or game — no extra window needed.
```

## Keywords (100 chars max, comma-separated, no spaces after commas)

```
GPU,utilization,monitor,dock,graph,history,activity,performance,system,usage,metal,apple silicon
```

_(That string is 96 chars. Do not add spaces after commas — they count.)_

## What's New (release notes, first version)

```
Initial release.
```

## Age rating

- 4+ (no objectionable content)

## App privacy (nutrition label)

- **Data collection**: None. Answer "No" to data collection in App Store
  Connect → App Privacy. Nutrition label renders as "Data Not Collected."

## Copyright

- `2026 Brian Birkinbine`

---

## Screenshots

At least one macOS screenshot at a supported size — **2560x1600** or
**2880x1800** (16:10), PNG or JPEG, RGB, no alpha.

The honest demo: the Dock showing the icon graphing under real load. Capture
the Dock during an Ollama/MLX run so the graph is visibly climbing.

- `docs/dock-screenshot.png` already exists but is a cropped tile — the store
  wants a full-size screenshot at one of the sizes above, not a crop.
- Quick capture: run a GPU load, then Shift-Cmd-4 the Dock region on a
  Retina display, or capture the full screen (Retina 2880x1800 native) and
  submit that.

---

## App Review notes (paste into the "Notes" field at submission)

```
GPU Dock History is a windowless utility that renders live GPU utilization
as a history graph on its own Dock tile (an Activity-Monitor-style CPU
history icon, but for the GPU).

GPU statistics are read using PUBLIC Apple APIs only:
IORegistryEntryCreateCFProperties over the IOAccelerator registry entry
(the "Device Utilization %" / PerformanceStatistics key). No private
frameworks, no IOReport, no IOKit user client, no entitlements beyond the
App Sandbox, no helper tools, and no sudo. The app runs sandboxed and
hardened.

The app is Apple-Silicon-only by design: the GPU utilization key is
published by Apple Silicon integrated GPUs. The binary ships an arm64-only
slice to express this.

Networking: none. Data collection: none.

To see the Dock graph respond during review, run any GPU-intensive task
(e.g. a local ML model, a game, or a WindowServer-heavy animation) and watch
the Dock icon fill with the green utilization history.
```

---

## Notes / dependencies (for Brian)

- **Privacy Policy URL needs hosting.** `docs/privacy-policy.md` is written and
  GitHub-Pages-ready, but Pages must be enabled: repo Settings -> Pages ->
  Source: "Deploy from a branch" -> branch `main`, folder `/docs`. The page
  then serves at the URL above. **Caveat:** GitHub Pages on a *private* repo
  requires a paid plan (Pro/Team) or making the repo public. If neither, host
  the one paragraph anywhere public (a Gist, a Netlify drop) and use that URL.
- **Support URL** assumes GitHub username `bbirkinbine` and repo
  `dock-gpu-history` — correct these if either differs.
- Everything else here is final copy; adjust to taste.
