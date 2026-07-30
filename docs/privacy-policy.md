---
title: Privacy Policy
---

# Privacy Policy — GPU Dock History

_Last updated: 2026-07-29_

GPU Dock History is a macOS utility that displays live GPU utilization as a
history graph on its own Dock icon, with an optional details window showing
the same data at a larger size alongside GPU memory totals and session
statistics.

## Summary

**GPU Dock History collects no data about you.** It has no analytics, no
telemetry, no crash reporting, no advertising, no account, and no network
access of any kind. Nothing it reads or displays ever leaves your Mac.

Everything below is detail supporting that statement.

## What the app reads

To draw the graph, the app reads the following from your Mac, on your Mac:

- **GPU utilization percentage**, from the local IOKit registry
  (`IOAccelerator` / `PerformanceStatistics`) using Apple's public
  `IORegistryEntryCreateCFProperties` API.
- **GPU hardware description** — the GPU's name, core count, and memory
  budget — via the Metal framework and a public `sysctl` read.
- **GPU memory allocated and in use**, system-wide totals in bytes, from the
  same IOKit registry properties. These are machine-wide figures; the app
  cannot attribute them to any process.

These are properties of your hardware, not of you. They contain no personal
information, no identifiers, and nothing tied to your files, applications,
accounts, or activity. The app cannot see which programs are using the GPU;
it only sees a single system-wide percentage.

All of these readings are used to draw the graph and then discarded. Sample
history is held in memory only, and is lost when the app quits.

## What the app stores

The app writes a small number of its own settings to the standard macOS
preferences system on your Mac. Because the app is sandboxed, these live
inside its own container at
`~/Library/Containers/com.bbirkinbine.gpu-dock-history/`.

The complete list:

- `sampleInterval` — how often the graph updates (1, 2, or 5 seconds).
- `graphColor` — your chosen graph tint.
- `hasLaunchedBefore` — a flag so the details window opens once, on first run.
- The details window's saved position and size.

That is everything. No GPU readings, no history, no usage records, and no
personal data are written to disk. Deleting the app removes these settings
along with it.

If you enable **Open at Login**, the app registers itself as a login item
with macOS using the system `ServiceManagement` framework. That registration
is held by macOS, not by the app, and turning the setting off removes it.

## Network access

The app makes no network connections. It contains no networking code, no
embedded browser, and no update checker. It uses only Apple system
frameworks — AppKit, Foundation, IOKit, Metal, and ServiceManagement — and
bundles no third-party SDKs, libraries, or services.

There is therefore no data to transmit, no server to receive it, and no third
party with access to anything.

## Permissions

The app requests no permissions. It does not ask for, and cannot access,
your files, photos, contacts, calendar, camera, microphone, location,
screen recording, or accessibility features. It runs inside Apple's App
Sandbox, which enforces these limits at the operating-system level rather
than relying on this policy as a promise.

## Your rights

Privacy regulations such as the GDPR and CCPA give you rights to access,
correct, delete, or port the personal data a developer holds about you, and
to know whether it is sold or shared.

No such data exists here. The developer holds no personal data about users
of this app, has no means of collecting any, and does not and cannot sell or
share it. There is nothing to request access to and nothing to delete. The
settings described above are on your own Mac, under your control, and are
never visible to anyone else.

## Children

The app is suitable for all ages and collects no data from anyone, including
children under 13.

## A note about the App Store

If you obtained the app from the Mac App Store, Apple may collect
information about the download and your use of the App Store itself, under
[Apple's privacy policy](https://www.apple.com/legal/privacy/). That
collection is Apple's and happens whether or not you run this app. The
developer receives only anonymous, aggregated sales and crash statistics
from Apple, which cannot identify individual users.

## Changes

If this policy changes, the updated version will be posted at this URL with
a new "Last updated" date above. Because the app collects nothing, any future
change that introduced data collection would be a significant one, and would
be described here and in the app's release notes.

## Contact

Questions about this policy can be raised as an issue on the project's
GitHub repository:
<https://github.com/bbirkinbine/dock-gpu-history/issues>
