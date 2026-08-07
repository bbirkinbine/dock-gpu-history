# Example Repos — free Mac App Store apps with public source

Comparable apps that ship **free on the Mac App Store while keeping a public
GitHub repo**, gathered to answer: is that combination normal, what license do
they use, and how (if at all) do they ask for money? Every row was verified
against the app's own App Store listing and its repo — price, in-app purchase
products, and license — not against roundup articles, which are frequently
stale on all three. Researched 2026-07-28; App Review policy and store prices
change, so re-verify before acting on any of it.

See also: [MONETIZATION.md](MONETIZATION.md) for the money decision itself
(this file is its evidence base), [STORE_LISTING.md](STORE_LISTING.md) for
pricing/developer-identity, and
[APP_STORE_PUBLISHING.md](APP_STORE_PUBLISHING.md) for store mechanics.

## The comparables

| App | What it is | Mac App Store | Repo (license, stars) | Where the money ask lives |
|---|---|---|---|---|
| **Hidden Bar** | Menu-bar icon hider; one feature | Free, no IAP | [dwarvesf/hidden](https://github.com/dwarvesf/hidden) (MIT, 14.5k) | Nowhere — no ask at all |
| **eul** | Menu-bar system monitor, SwiftUI | Free, no IAP | [gao-sun/eul](https://github.com/gao-sun/eul) (MIT, 9.9k) | GitHub Sponsors button on the repo |
| **NetNewsWire** | RSS reader, Mac + iOS | Free, no IAP | [Ranchero-Software/NetNewsWire](https://github.com/Ranchero-Software/NetNewsWire) (MIT, 10.2k) | Nowhere |
| **LocalSend** | AirDrop alternative | Free + donation IAPs ($5 / $10 / $20 / $50) | [localsend/localsend](https://github.com/localsend/localsend) (Apache-2.0, 86k) | In-app, via IAP |
| **MeetingBar** | Menu-bar meeting launcher | Free + "Optional Patronage" IAP ($2.99/3mo, $5.99/6mo, $11.99/yr) | [leits/MeetingBar](https://github.com/leits/MeetingBar) (Apache-2.0, 5.3k) | In-app IAP **and** Patreon + Buy Me a Coffee in the README |
| **Clocker** | Menu-bar world clock | Free + "Clocker Pro Lifetime" IAP ($19.99) | [n0shake/Clocker](https://github.com/n0shake/Clocker) (README says MIT; **no LICENSE file**, 616) | PayPal link in the README; the store side sells Pro |

Counterexamples that frame the choice:

- **Maccy** — [p0deje/Maccy](https://github.com/p0deje/Maccy) (MIT, 21k). Free
  from GitHub and Homebrew, **$10 on the Mac App Store** for the same app.
  The reference model already described in [MONETIZATION.md](MONETIZATION.md);
  public source costs you nothing legally if you later want to charge.
- **Stats** — [exelban/stats](https://github.com/exelban/stats) (MIT, 41k).
  The closest peer app to this one by function, and it is **not on the Mac App
  Store at all**: it installs a privileged SMC helper daemon
  (`eu.exelban.Stats.SMC.Helper`), which the sandbox forbids outright. Its
  absence is a sandbox constraint, not a licensing or policy one — and the
  sandbox check in APP_STORE_PUBLISHING.md Section 0 already proved this app
  falls on the other side of that line.

## Three postures, and what each costs

1. **Free both places, identical build, no ask** — Hidden Bar, NetNewsWire.
   Zero legal surface: no Paid Applications agreement, no banking or tax
   forms, no EU trader declaration, no StoreKit code.
2. **Free both places + off-store donations only** — eul (repo Sponsor
   button). Same zero legal surface as above; App Review never sees an ask.
3. **Free both places + money via IAP** — LocalSend, MeetingBar, Clocker.
   Approved and shipping at scale, but it takes the full Paid Apps agreement
   plus EU trader status (public address and phone on EU store pages). Two of
   the three hedge by also running off-store channels.

## Where the ask may live (verified against the guidelines)

| Placement | Verdict |
|---|---|
| Repo Sponsor button / Ko-fi / BMAC on the project site | Fine — outside Apple's jurisdiction entirely |
| App Store listing's website field pointing at a page that has a donate button | Fine in observed practice: eul's own store description carries its GitHub URL, and the Sponsor button sits one click away on the far end |
| Consumable "tip" IAP inside the app | Allowed. Apple has permitted tip-jar IAPs since 2017, and LocalSend/MeetingBar are live proof for non-nonprofits |
| A Buy Me a Coffee **link** inside a Mac App Store build | Rejection. See the case below |

The rejection case is documented in detail: a free iOS puzzle game carrying
nothing but a discreet BMAC link that opened Safari — no gating, no feature
unlock — was rejected under 3.1.1 ("Your app includes an external link for
purchasing digital content or services that is not processed via the In-App
Purchase API"). Four rounds followed, including two appeals reopened after the
Epic ruling and a phone call with Apple. Apple held; the app never shipped
(May 2025).

Two traps worth recording, because both look like escape hatches and are not:

- **The post-Epic US-storefront allowance does not obviously reach the Mac App
  Store.** Guideline 3.1.1(a) drops the external-link prohibition for United
  States storefront apps, but the surrounding entitlement text scopes itself
  to "the iOS or iPadOS App Store in specific storefronts," and the injunction
  behind it concerns the iOS App Store. A MAS build should not be planned
  around it. (This narrows the more optimistic reading in
  [MONETIZATION.md](MONETIZATION.md) Option 4.)
- **Guideline 3.2.1(vii) is not a developer tip jar.** It permits a gift from
  one *individual user to another*, and voids itself if the gift is "connected
  to or associated at any point in time with receiving digital content or
  services." User-to-developer support is not what it covers.

Charity fundraising is a separate clause again (3.2.2(iv): must be free, funds
collected outside the app) and does not apply to funding your own work.

## What this suggests for GPU Dock History

- The combination Brian asked about — free on the store, public repo — is the
  category norm, not an exception, and it survives review with the source
  fully public and even linked from the store description.
- Posture 2 (free + repo Sponsor button, nothing in the binary) is what
  [MONETIZATION.md](MONETIZATION.md) already recommends, and eul is the
  working demonstration of it in this exact app category. **Adopted
  2026-08-07** — with Stats' channels (GitHub Releases + Homebrew) added on top,
  since nothing here forces the store-or-nothing choice either way. See
  [DISTRIBUTION.md](DISTRIBUTION.md).
- **License:** MIT or Apache-2.0 across the board; the one to avoid is GPL,
  whose redistribution terms conflict with the App Store's usage rules — the
  conflict that got VLC pulled. Apple does not police it; the copyright holder
  does, so a sole-author MIT repo has no exposure. This repo is already MIT.
- **Repo hygiene matters more than it looks.** Clocker states MIT in its
  README with no LICENSE file in the repo, so GitHub detects no license and,
  strictly read, the code is all-rights-reserved. If this repo goes public,
  the existing `LICENSE` file is what makes the grant real.
- **Incidental find, relevant to a current blocker:** Hidden Bar's App Store
  privacy-policy URL points straight at
  `github.com/dwarvesf/hidden/blob/develop/PRIVACY_POLICY.md` — a markdown
  file in the repo. Apple accepted it. That is a cheaper answer to the
  unhosted privacy-policy URL in [STORE_LISTING.md](STORE_LISTING.md) than
  GitHub Pages or a paid plan, though it still requires the repo to be public.

## Sources

Verified 2026-07-28. App Store listings (price and IAP products read from the
listing itself), repos (license and stars read via the GitHub API):

- Hidden Bar: [Mac App Store](https://apps.apple.com/in/app/hidden-bar/id1452453066?mt=12) · [dwarvesf/hidden](https://github.com/dwarvesf/hidden)
- eul: [Mac App Store](https://apps.apple.com/us/app/eul/id1537133867?mt=12) · [gao-sun/eul](https://github.com/gao-sun/eul)
- NetNewsWire: [Mac App Store](https://apps.apple.com/us/app/netnewswire-rss-reader/id1480640210) · [Ranchero-Software/NetNewsWire](https://github.com/Ranchero-Software/NetNewsWire)
- LocalSend: [Mac App Store](https://apps.apple.com/us/app/localsend/id1661733229) · [localsend/localsend](https://github.com/localsend/localsend)
- MeetingBar: [Mac App Store](https://apps.apple.com/us/app/meetingbar/id1532419400?mt=12) · [leits/MeetingBar](https://github.com/leits/MeetingBar)
- Clocker: [Mac App Store](https://apps.apple.com/us/app/clocker/id1056643111?mt=12) · [n0shake/Clocker](https://github.com/n0shake/Clocker)
- Maccy: [Mac App Store](https://apps.apple.com/us/app/maccy/id1527619437?mt=12) · [p0deje/Maccy](https://github.com/p0deje/Maccy)
- Stats: [exelban/stats](https://github.com/exelban/stats) (no store listing)

Policy:

- [Apple — App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/) (3.1.1, 3.1.1(a), 3.2.1(vi)(vii), 3.2.2(iv))
- [Robert Baer — the Buy Me a Coffee link rejection, start to finish](https://medium.com/@robert-baer/my-ongoing-battle-with-apple-over-a-buy-me-a-coffee-link-is-over-9c158df81c05)
- [9to5Mac — guidelines updated to allow external payment links, US storefront, May 2025](https://9to5mac.com/2025/05/01/apple-app-store-guidelines-external-links/)
- [iDownloadBlog — Apple permits tip jars via in-app purchase (2017)](https://www.idownloadblog.com/2017/06/09/apple-now-allowing-developers-to-implement-digital-tip-jars-via-in-app-purchase-mechanism/)
- [FSF — the VLC/App Store GPL conflict](https://www.fsf.org/blogs/licensing/vlc-enforcement)

Finding more comparables: `gh search repos "apps.apple.com" --language=swift
--match=readme --stars=">300"` works but is noisy (SDKs and awesome-lists
dominate). Filtering by the `mac-app-store` GitHub topic, or grepping READMEs
for `mt=12` (the Mac-only storefront suffix), is a cleaner filter.
