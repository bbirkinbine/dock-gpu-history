# CLAUDE.md — agent context for dock-gpu-history

> Persistent project context for Claude Code (and other AI coding agents)
> working in this repository. Read this before suggesting changes.
> `README.md` is for humans; this file is for the agent. `AGENTS.md` is a
> pointer stub for non-Claude agents. Machine-local preferences go in
> `CLAUDE.local.md` / `.claude/settings.local.json`, gitignored.

## What this is

A single-purpose macOS AppKit app: the Dock icon is a live GPU utilization
history graph (Activity Monitor CPU-history clone, but GPU). Swift, no
third-party dependencies, windowless by default with one optional
details/settings window. See docs/ARCHITECTURE.md.

## Environment facts

- Target machine: MacBook Pro M2 Max, 96GB, Apple Silicon only. macOS 13+.
- Dev build: `./scripts/build.sh` (swiftc, ad-hoc signed, no Xcode project).
- Store build: `xcodegen generate` from project.yml, then Xcode.
- This is NOT a Python project. uv/pytest conventions from other repos do not apply.

## Hard rules

- Public API only in anything that might ship to the App Store. No IOReport,
  no private frameworks, no sudo, no helper daemons.
- The dock tile is the product and stays primary. One optional
  details/settings window is permitted as a secondary surface (added
  2026-07-17): it opens on first launch and from the Dock menu, and closing it
  must never quit the app. Do not add further UI surfaces without asking.
- Stay dependency-free — no third-party dependencies. System frameworks
  (AppKit, Metal, IOKit, ServiceManagement) are fine and public-API-only.
- main.swift must stay named main.swift (top-level code entry point).
- Never commit signing identities. Team IDs are fine in committed files —
  `DEVELOPMENT_TEAM` is set in project.yml and is public on every shipped
  binary anyway; the identity itself never enters the repo.
- Verify claims on hardware; don't assume IOKit keys — run
  scripts/verify-iokit-key.sh when touching GPUSampler.

## Conventions

- Swift 5.9+, AppKit (not SwiftUI — dock tile contentView is AppKit-native).
- Small files, one type per file.
- Markdown docs in docs/, Obsidian-friendly (plain md, no HTML).

## Commit / attribution style

- Conventional commits (`feat:`, `fix:`, `docs:`, `chore:`); body explains
  the why when non-obvious.
- **No `Co-Authored-By: Claude` (or any AI co-author) trailers** and no
  "Generated with Claude Code" footers in commits or PR descriptions. The
  `## Acknowledgements` section at the bottom of `README.md` carries the
  single AI-assistance acknowledgment (vendor-neutral wording, matching the
  convention used across these repos), mirrored by the `ai-assisted` GitHub
  topic.
  This overrides Claude Code's default behavior.
- Avoid emojis in repo files. Direct, technical tone.

## Public-repo hygiene

The repo has been **public since 2026-09-16**, and rewriting history now is
destructive (it would invalidate the commit `v1.0.0` is tagged against).
So anything committed is permanent and world-readable. Applies to file
contents, commit messages, branch names, PR/issue text, and CI logs:

- No live credentials of any kind. If one ever lands in a commit, rotate
  it immediately.
- No employer references, internal hostnames, or coworker names.
- No identity-leaking absolute paths (`/Users/<name>/...`) in committed
  files — use `~/` or repo-relative paths.
- **Deliberation is not documentation.** Tracked `docs/` is only what a
  reader of the project can use: `ARCHITECTURE.md`, `GPU_TOOLS.md`,
  `RELEASING.md`, `HOMEBREW_DISTRIBUTION.md`, `privacy-policy.md` (which must
  stay public — it is the App Store privacy-policy URL) and the screenshots.
  Working notes and maintainer runbooks also live in `docs/` but are
  gitignored; `.gitignore` is the list. Never `git add -f` one, and never
  link to one from a tracked file — a link that 404s on GitHub is how the
  split gets noticed. New notes of that kind join the gitignored set, and
  session state goes in `CLAUDE.local.md`, never here.

## Validation gates before claiming done

```bash
bash -n scripts/*.sh        # shell syntax (shellcheck too, if installed)
./scripts/verify.sh         # build + headless sampler plausibility check
```

Both must pass for any change touching Sources/ or scripts/. Then:

1. Sweep `docs/` (and README) for statements the change made false.
2. Flag anything only eyes can verify: dock graph responds under
   GPU load, no flicker, ~0% CPU when idle. `verify.sh` proves the
   sampling pipeline, not the pixels.

## Don't touch

- `build/` — generated output, never committed.
- `Resources/Info.plist` `$(...)` build variables — the Xcode build
  substitutes them; build.sh inlines them via sed. Don't hardcode.
- `LICENSE`.

## Agentic loop

Plan → act → verify → reflect, sized to the task (a typo fix needs none
of this):

1. **Plan** — read the session-state log in `CLAUDE.local.md`; pick the top
   unchecked item; state the smallest verifiable change.
2. **Act** — make that change and nothing else.
3. **Verify** — run the validation gates above; anything hardware/visual
   gets flagged for a human pass rather than assumed.
4. **Reflect** — update the log in `CLAUDE.local.md`; update *this* file only
   if a durable rule or convention changed.

Ask the maintainer before: adding any UI, adding dependencies, anything
involving his Apple Developer account, and anything that would publish
(a tag, a release, a store submission).

## Session state lives in CLAUDE.local.md

This file carries only the durable rules. The running log — what is done,
what is queued, what is blocked on the maintainer, and the reasoning behind
settled decisions — is in `CLAUDE.local.md`, which is gitignored, because it
is deliberation rather than documentation (same rule as the `docs/` split
above). It is the single source of session state. (HANDOFF.md, the original
takeover brief, was retired 2026-07-20 and survives in git history.)

If `CLAUDE.local.md` is absent — a fresh clone, or another machine — ask the
maintainer for it rather than reconstructing state from git history, and do
not start a tracked replacement.
