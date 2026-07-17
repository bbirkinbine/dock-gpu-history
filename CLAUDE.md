# CLAUDE.md — agent context for dock-gpu-history

> Persistent project context for Claude Code (and other AI coding agents)
> working in this repository. Read this before suggesting changes.
> `README.md` is for humans; this file is for the agent. `AGENTS.md` is a
> pointer stub for non-Claude agents. Machine-local preferences go in
> `CLAUDE.local.md` / `.claude/settings.local.json`, gitignored.

## What this is

A single-purpose macOS AppKit app: the Dock icon is a live GPU utilization
history graph (Activity Monitor CPU-history clone, but GPU). Swift, no
dependencies, no window. See docs/ARCHITECTURE.md.

## Environment facts

- Target machine: MacBook Pro M2 Max, 96GB, Apple Silicon only. macOS 13+.
- Dev build: `./scripts/build.sh` (swiftc, ad-hoc signed, no Xcode project).
- Store build: `xcodegen generate` from project.yml, then Xcode.
- This is NOT a Python project. uv/pytest conventions from other repos do not apply.

## Hard rules

- Public API only in anything that might ship to the App Store. No IOReport,
  no private frameworks, no sudo, no helper daemons.
- Keep the app windowless and dependency-free unless a task explicitly says
  otherwise. The dock tile is the product.
- main.swift must stay named main.swift (top-level code entry point).
- Never commit signing identities. Team IDs in committed files are OK but
  keep DEVELOPMENT_TEAM commented in project.yml until publishing.
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
  single AI-assistance acknowledgment (vendor-neutral wording, matching
  agentic-scaffold), mirrored by the `ai-assisted` GitHub topic.
  This overrides Claude Code's default behavior.
- Avoid emojis in repo files. Direct, technical tone.

## Public-repo hygiene

The repo is private today; treat it as **public from commit #1** — it may
flip later, and rewriting history after that is destructive. Applies to
file contents, commit messages, branch names, PR/issue text, and CI logs:

- No live credentials of any kind. If one ever lands in a commit, rotate
  it immediately.
- No employer references, internal hostnames, or coworker names.
- No identity-leaking absolute paths (`/Users/<name>/...`) in committed
  files — use `~/` or repo-relative paths.

## Validation gates before claiming done

```bash
bash -n scripts/*.sh        # shell syntax (shellcheck too, if installed)
./scripts/verify.sh         # build + headless sampler plausibility check
```

Both must pass for any change touching Sources/ or scripts/. Then:

1. Sweep `docs/` (and README) for statements the change made false.
2. Flag for Brian anything only eyes can verify: dock graph responds under
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

1. **Plan** — read HANDOFF.md's task checklist and the Open work section
   below; pick the top unchecked item; state the smallest verifiable change.
2. **Act** — make that change and nothing else.
3. **Verify** — run the validation gates above; anything hardware/visual
   gets flagged to Brian rather than assumed.
4. **Reflect** — update HANDOFF.md checkboxes and the Open work section;
   update this file if a convention changed.

Ask Brian before: making the repo public, adding any UI, adding
dependencies, anything involving his Apple Developer account.

## Open work / current state (updated 2026-07-17)

- Done: IOKit key verified on M2 Max (`Device Utilization %` present);
  dev build compiles and runs; headless verify gate (`scripts/verify.sh`);
  git initialized and pushed to private GitHub repo.
- Next: Brian eyeballs the dock graph under GPU load (flicker, idle CPU);
  then HANDOFF tasks 5–6 (XcodeGen build, sandbox check).
- Blocked on Brian: task 7 (App Store prerequisites) — needs his go.
