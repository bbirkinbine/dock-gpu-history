# Distribution channels

How this app reaches users. This is the hub: the decision and what falls out of
it live here, the per-channel mechanics live in the companion docs.

See also: [APP_STORE_PUBLISHING.md](APP_STORE_PUBLISHING.md) (store mechanics),
[HOMEBREW_DISTRIBUTION.md](HOMEBREW_DISTRIBUTION.md) (cask mechanics),
[RELEASING.md](RELEASING.md) (versioning and cutting a release),
[EXAMPLE_REPOS.md](EXAMPLE_REPOS.md) (the comparables this is based on).

## The decision (2026-08-07)

**Follow the Stats distribution model, and add the Mac App Store — because this
app can, and Stats cannot.**

Concretely: free everywhere, public MIT repo, donations off-store only, one
build shipped through three channels.

| # | Channel | Artifact | Status |
|---|---|---|---|
| 1 | GitHub Releases | notarized + stapled `.app` zip | **live — [v1.0.0](https://github.com/bbirkinbine/dock-gpu-history/releases/tag/v1.0.0)** |
| 2 | Homebrew cask (own tap) | points at the channel-1 zip | not created |
| 3 | Mac App Store | archive uploaded via Xcode | blocked — see the ordering section |

Channel 1 is the substrate: channel 2 is a pointer to its release asset, and
channel 3 is the only one that carries its own artifact.

## Why this shape rather than just copying Stats

[exelban/stats](https://github.com/exelban/stats) ships via GitHub Releases +
Homebrew with a Sponsors link, and is **not on the Mac App Store at all**. That
absence is a constraint, not a preference: Stats installs a privileged SMC helper
daemon (`eu.exelban.Stats.SMC.Helper`) to read sensors, and the App Sandbox
forbids that outright.

This app was verified to fall on the other side of that line —
`APP_STORE_PUBLISHING.md` Section 0, tested 2026-07-17 under an enforced sandbox
with live values under GPU load. So the store is available here and is not
available to Stats. Copying Stats wholesale would mean discarding a channel they
would take if they could.

The closest documented peer for the resulting posture is **eul** — free on the
Mac App Store, public MIT repo, GitHub Sponsors button on the repo, nothing in
the binary. See "Three postures, and what each costs" in
[EXAMPLE_REPOS.md](EXAMPLE_REPOS.md); this is posture 2 with Stats' channels
added.

## Consequences

**One build configuration, sandboxed, for all three channels.** The sandbox does
not block the IORegistry read, so there is no reason to maintain a second
unsandboxed build for the direct channel. Developer ID signing and the
`com.apple.security.app-sandbox` entitlement are a supported combination, and
this app needs no temporary-exception entitlements — it reads IORegistry
properties and `UserDefaults`, both of which work inside the container. One
configuration means one thing to test.

Caveat on that claim: the sandbox was verified under an **ad-hoc** signature
(APP_STORE_PUBLISHING.md Section 0), not under a Developer ID one. The sandbox's
rules depend on entitlements rather than the signer, so this should hold — but
confirm it on the first notarized build before assuming it, and be ready to drop
the entitlement for the direct channel if a provisioning-profile requirement
surfaces.

**There is no in-app updater, and there will not be one.** Sparkle is a
third-party dependency, which the hard rules forbid. The store updates itself;
`brew upgrade` updates the cask. Anyone who downloads the raw zip from a GitHub
Release gets **no update path at all**. So the README's install instructions
should lead with Homebrew and treat the bare zip as the fallback for people who
do not use it.

**Same bundle ID in every channel.** A machine that installs both the store copy
and the cask copy ends up with two `/Applications` bundles claiming
`com.bbirkinbine.gpu-dock-history`, which LaunchServices resolves
unpredictably — and launch-at-login, whose source of truth is
`SMAppService.mainApp`, is registered per bundle. Homebrew's `conflicts_with`
only arbitrates cask against cask, so the store copy has to be called out in the
cask's `caveats` instead. Declare it when the cask is written.

**Version parity is already handled.** [RELEASING.md](RELEASING.md) assumes a
single release feeding all channels: one `MARKETING_VERSION` shared by the tag,
the zip, the cask, and the store listing, with `CURRENT_PROJECT_VERSION`
incremented once per release as a monotonic counter across all three channels.
No change needed there.

**Cost is unchanged.** The same $99/yr Apple Developer Program membership covers
Developer ID signing, notarization, and App Store Connect. Already active
(Team ID `G82L6VKCXZ`).

## Ordering: direct and Homebrew first, store second

The blockers are asymmetric.

Channels 1 and 2 need exactly two things that do not exist yet: a Developer ID
certificate and a notarytool keychain profile, so the app can be signed,
notarized, and stapled. No review, no privacy-policy URL, no App Store Connect
record, no screenshots.

They also need **no Xcode.app** — measured 2026-09-16 while writing
`scripts/release.sh`, which compiles, signs, notarizes, staples and packages
using only the Command Line Tools. `actool` is the one tool it lacks, so the
icon is built as an `.icns` with `iconutil` instead of a compiled asset
catalog; the store archive still uses the catalog. This narrows the asymmetry
below: full Xcode is a channel-3 requirement only.

Channel 3 needs all of that plus full Xcode for the Archive, a hosted
privacy-policy URL, an App Store Connect record with a globally unique app name,
screenshots at 2560x1600 or 2880x1800 under real GPU load, and a review pass
whose likeliest rejection is 4.2.

Shipping 1 and 2 first also produces the traction the store decision wants
anyway, and it
puts the app in front of exactly the audience that installs this class of tool
with `brew`.

Honest caveat: Developer ID signing mints a certificate on the Apple account, so
the reason the Archive has been deliberately deferred applies to this path too.
It is a smaller step, not a free one.

## This shape requires the repo to be public

Not a side effect — a precondition, and it collapses two open blockers at once:

- A Homebrew cask downloads its artifact over plain HTTPS with no credentials.
  Release assets on a private GitHub repo require an authenticated request, so a
  private repo cannot back a public cask without hosting the zip somewhere else.
- The unhosted privacy-policy URL stops being a blocker. Hidden Bar's accepted
  App Store privacy-policy URL points straight at a markdown file in its repo
  (`EXAMPLE_REPOS.md`, "Incidental find") — no GitHub Pages, no paid plan, no
  Netlify drop. `docs/privacy-policy.md` is already written.

Going public is Brian's call and is tracked in CLAUDE.md's blocked list. Nothing
else in this document can proceed without it except a manually downloaded zip.

**One thing has to land before the switch is flipped, not after:** a written
contribution policy. Once outside contributors' code lands it is theirs, MIT
licensed *to* the maintainer rather than by him, so relicensing — including any
future paid-store option — would need their
agreement from that point on. An issue-first policy in `CONTRIBUTING.md` is what
keeps that door open, and the first drive-by pull request is too late to write
one. Queued in CLAUDE.md.

## Where the money ask lives

Off-store only: a GitHub Sponsors button on the repo, and nothing whatsoever in
the binary. This is posture 2 in [EXAMPLE_REPOS.md](EXAMPLE_REPOS.md), and the
standing recommendation.

The trap that makes this non-obvious: a donation **link inside a Mac App Store
build** is a 3.1.1 rejection, documented case and all, and the post-Epic
external-link allowance is scoped to iOS/iPadOS storefronts rather than the Mac
App Store. A Sponsors button on the repo is outside Apple's jurisdiction
entirely, and eul demonstrates that the store description may carry the repo URL
with the button one click away on the far end.
