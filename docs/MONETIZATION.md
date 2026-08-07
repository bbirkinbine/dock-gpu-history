# Monetization Options

How (if at all) to make money from GPU Dock History: charging on the Mac App
Store, in-app tips, donation platforms (GitHub Sponsors, Ko-fi, Buy Me a
Coffee, Patreon), and direct sales — plus the App-Review-rejection fallback,
the argued case for a flat $1 price (taxes included), and the open-source vs
closed-binary decision given the MIT license in a still-private repo.
Researched 2026-07-20; fees and App Review policy change often — re-verify
before acting. Sources at the end.

See also: [EXAMPLE_REPOS.md](EXAMPLE_REPOS.md) for verified comparables (free
MAS apps with public repos, their licenses, and where each puts its money ask
— the evidence base for the recommendations here),
[APP_STORE_PUBLISHING.md](APP_STORE_PUBLISHING.md) for store mechanics,
[STORE_LISTING.md](STORE_LISTING.md) for the current (free) pricing decision
and developer-identity notes, and
[HOMEBREW_DISTRIBUTION.md](HOMEBREW_DISTRIBUTION.md) for the direct channel.

## TL;DR recommendation

1. **Ship free** on the Mac App Store and via Homebrew (as currently planned).
   Free means no Paid Applications agreement, no banking/tax forms, and —
   critical for name privacy — a plausible **non-trader** declaration in the
   EU, keeping personal contact details off the store page.
2. **Accept donations outside the app**: a GitHub Sponsors profile (0% fees,
   natural for this app's developer audience) plus optionally Ko-fi (0% on
   one-time tips). Put the links in the README, the GitHub repo's Sponsor
   button, and the support-URL page — **not inside the app binary**, which
   keeps App Review entirely out of the picture.
3. **Revisit paid-on-MAS later** (the Maccy model: open source, free to build,
   $9.99 for the store convenience build) only if the app earns real traction.
   Charging anywhere — even an IAP tip jar — flips EU trader status on and
   publishes a contact address/phone/email, so it is not a casual switch.
4. **An App Store rejection changes nothing** — Developer ID + Homebrew
   distribution is unreviewed, donations stay fully legal (and the link may
   then even live inside the app), and this category's most successful apps
   ship exactly that way. See "Plan B" below.
5. **A $1 price is the worst of both worlds** — all the paperwork and privacy
   cost of charging, revenue that plausibly never clears Apple's $99/yr fee,
   and it forfeits the goodwill/portfolio value of a free tool. Argued in
   full below; if ever charging, charge $4.99–9.99, not $1.

## Constraints specific to this app

- First-time publisher, individual Apple enrollment likely → legal name is
  already on the store page; a **public postal address + phone** (EU trader
  requirement) would be a further privacy step that charging money triggers.
- Audience is developers / local-AI users; Homebrew may matter more than the
  App Store. That audience is exactly who GitHub Sponsors reaches.
- Dependency-free codebase; an IAP tip jar would add StoreKit code and App
  Store Connect product management for what is typically negligible revenue.
- Repo is private today but treated as public-from-commit-1; the licensing
  decision (see the vault's Release Types, Licensing & Support note) interacts
  with monetization — a permissive license permits others to sell your build,
  and also permits *you* to sell a store build while the source stays free.

## Option 1 — Free everywhere (status quo)

What the repo currently plans ([STORE_LISTING.md](STORE_LISTING.md): Free).

- No Paid Applications agreement, banking, or tax forms in App Store Connect.
- EU DSA: a genuinely non-commercial free app can usually declare
  **non-trader** → no public address/phone on EU storefronts. (Verify the
  current questionnaire at submission; the rule has evolved.)
- Zero accounting; zero support expectation of paying customers.
- Revenue: $0 by construction.

## Option 2 — Paid app on the Mac App Store

Charge up front ($0.99–$9.99 is the normal band for single-purpose macOS
utilities; Maccy charges $9.99).

- **Apple's cut**: 30% standard, **15% via the App Store Small Business
  Program** (free enrollment, applies while proceeds < $1M/yr; must actively
  enroll in App Store Connect — it is not automatic).
- **Setup**: Paid Applications agreement (Schedule 2), banking details, and
  tax forms (W-9 for a US individual) in App Store Connect. Apple acts as
  merchant of record — it handles worldwide VAT/sales tax, refunds, and
  payment processing; you receive proceeds and report them as income.
- **EU trader status**: charging makes you a **trader** under the DSA
  regardless of size → address, phone, and email **publicly displayed** on EU
  store pages (PO box / mail-forwarding address is acceptable; or remove the
  app from EU storefronts entirely).
- **Open-source interplay — the Maccy model**: Maccy is MIT-licensed on
  GitHub, free via Homebrew and free to build from source, and sells the same
  app for $9.99 on the Mac App Store "to support development." Buyers pay for
  convenience, automatic updates, and supporting the developer. This model is
  proven and fits this repo if it goes public under MIT — but it works best
  once an app has an audience; day-one paid kills discovery for an unknown
  utility.
- Sales expectations should be modest: niche single-purpose menu-bar/dock
  utilities from unknown developers typically sell single-digit copies per
  week at best.

## Option 3 — Free app + in-app tip jar (IAP)

Guideline 3.1.1 explicitly permits tipping the developer **through in-app
purchase** (consumable IAPs named e.g. "Nice tip $1.99").

- Same paperwork as Option 2 (Paid Apps agreement, banking, tax) and the same
  EU trader consequence — IAP revenue is commercial revenue.
- Apple takes its 15/30% cut of tips.
- Requires StoreKit integration, IAP products in App Store Connect, and App
  Review of the purchase flow — real code and ops added to a deliberately
  dependency-free app.
- Industry experience: tip-jar conversion is famously tiny (fractions of a
  percent of users). For a niche utility the expected value does not cover
  the added complexity. **Not recommended.**
- Precedent confirmed 2026-07-28: this does pass review for ordinary
  developers, not just nonprofits — LocalSend ships free with $5/$10/$20/$50
  "Donation" IAPs and MeetingBar with $2.99/$5.99/$11.99 "Optional Patronage"
  IAPs, both alongside public repos (see
  [EXAMPLE_REPOS.md](EXAMPLE_REPOS.md)). The recommendation is unchanged: the
  blocker was never approvability, it is the EU trader trigger and the
  StoreKit code.

## Option 4 — Free app + external donation links

The zero-Apple-paperwork path: keep the app free and let people donate via a
third-party platform.

**Where the link can live:**

| Placement | App Review risk |
|---|---|
| GitHub README / repo Sponsor button | None — Apple irrelevant |
| Support URL page (linked from store listing) | None in practice — reviewers check the app binary; marketing-page donation links are the community norm (Maccy's store listing coexists with its Buy Me a Coffee page) |
| Inside the app (About/details window, Dock menu) | Rejected under 3.1.1 ("no external links to other purchasing mechanisms"). The May 2025 Epic ruling dropped that prohibition for **US storefront** apps with no entitlement and (currently) no commission — but re-read 2026-07-28, the surrounding entitlement text scopes itself to "the iOS or iPadOS App Store," and the injunction concerns the iOS App Store, so **a Mac App Store build should not be planned around it**. Also: a Dec 2025 appeals decision lets Apple seek a "reasonable commission" later, other storefronts still prohibit it, and the documented Buy Me a Coffee rejection (a free game, link opened Safari, no gating) survived four rounds of appeal including two reopened post-Epic. Keep links out of the MAS binary. |
| Inside the Developer ID / Homebrew build | None — no review exists. If ever useful, the direct build could carry a "Support development" menu item the MAS build omits. |

**Platform comparison (2026 fees):**

| Platform | Platform fee | Processing | Notes |
|---|---|---|---|
| **GitHub Sponsors** | 0% for personal accounts | absorbed by GitHub for personal sponsorships | Best fit for a dev-audience repo; Sponsor button on the repo; payouts via Stripe Connect |
| **Ko-fi** | 0% on one-time tips | Stripe/PayPal ~2.9% + $0.30 | Memberships/shop need Gold ($6/mo, still 0% fee) |
| **Buy Me a Coffee** | 5% | ~3% | Most recognizable "coffee" branding |
| **Patreon** | 5–12% by plan | ~3%+ | Membership-oriented; overkill for a utility |
| **Liberapay / Open Collective** | 0% / ~10% | varies | FOSS-culture options; Open Collective adds fiscal-host transparency |

Donations are still taxable income in the US (hobby income on the 1040 if not
a trade/business), but involve no Apple agreements and no EU trader trigger —
the app itself remains non-commercial.

**Recommended combo**: GitHub Sponsors (primary, 0% fees, one-click for the
target audience) + Ko-fi or Buy Me a Coffee (for non-GitHub users).

## Option 5 — Sell direct, outside the App Store

Developer ID + notarized build sold from a website via a **merchant of
record** (Paddle, Lemon Squeezy, Gumroad — ~5%+ fees, they handle global
VAT/sales tax) or raw Stripe (~3%, but then *you* owe international tax
compliance).

- Requires a licensing layer: payment webhook → license key issuance →
  in-app license validation, plus a storefront page and customer support.
- This is the right model for $20+ pro apps with trials; for a small free
  utility it is disproportionate ops and code. **Not recommended** — noted
  for completeness and in case a future paid "pro" sibling app ever exists.

## Decision interactions (read before changing the pricing)

- **Any charging** (paid app, IAP tips) → Paid Apps agreement + banking + tax
  forms + EU trader status (public contact info) — the privacy cost is the
  real price, not the paperwork.
- **Donations outside the app** → none of the above; compatible with the
  current free/non-trader plan, and can start before Apple enrollment even
  happens (a Sponsors profile needs only the GitHub account).
- **Going paid later is easy** (flip the price in App Store Connect after
  signing agreements); **going free later is also easy but refunds goodwill**
  — early buyers paid for what others now get free. Starting free and adding
  a paid convenience tier (Maccy model) is the smoother direction.

## Plan B — if App Review rejects the app

The rejection scenario (Guideline 4.2 minimum-functionality is the known
risk) removes the App Store, not the app:

- **Developer ID + notarization is not App Review.** Notarization is an
  automated malware scan — no human review, no content guidelines, no 4.2.
  The same $99/yr membership covers it. GitHub Releases + Homebrew cask
  distribution proceeds exactly as planned in
  [HOMEBREW_DISTRIBUTION.md](HOMEBREW_DISTRIBUTION.md).
- **Donations become entirely unconstrained.** Outside the store, Apple has
  no jurisdiction over the binary: a "Support development" item in the Dock
  menu or details window linking to Buy Me a Coffee / Ko-fi / GitHub Sponsors
  is fine — the 3.1.1 problem only ever applied to the MAS build.
- **Is Buy Me a Coffee legally sound?** Yes, with three qualifiers:
  1. *It is income, not gifts.* Despite the "donation" framing, the IRS and
     the platforms treat creator tips as ordinary (typically self-employment)
     income. Report it whether or not any form arrives.
  2. *Never imply tax deductibility.* Donors get no deduction — that requires
     501(c)(3) status. Phrase it "support development," not "donate to a
     cause."
  3. *Paperwork thresholds are high.* BMAC issues no tax forms itself; its
     processor Stripe issues a 1099-K only above **$20,000 AND 200
     transactions** per year (the OBBBA restored this threshold for 2025+,
     killing the planned $600 trigger). A hobby-scale tip stream generates
     no forms — but stays reportable.
- **Platform reliability caveat:** BMAC has recurring creator complaints
  about payout delays and account freezes; GitHub Sponsors (0%, Stripe
  Connect payouts) and Ko-fi (0% one-time, direct to your PayPal/Stripe) have
  cleaner records. Another reason Sponsors-first, BMAC as the recognizable
  extra.

Net: Plan B is the *same* recommendation (free + external donations), minus
the store, plus the freedom to put the link in the app. Rejection is an
inconvenience, not a strategy change.

## The $1 flat-rate case, argued

The steelman for "just charge a dollar":

- Money is cleaner than tips — buyers self-select, no begging UI.
- Apple is merchant of record: taxes on the sale itself (VAT etc.) are
  Apple's problem; you get ~$0.85/copy after the 15% Small Business cut.
- Payouts are practical even at tiny volume: the minimum payment threshold
  for a US bank is only $10, rolled forward until reached.
- The Paid Apps agreement is one-time paperwork (W-9, banking) — annoying,
  not hard.

The counter, with numbers:

- **Realistic volume is tiny.** Over 80% of paid apps sell nearly nothing; a
  documented comparable (a $1.99 battery-monitor Mac utility) sold ~500
  copies in its first months — *with* a MacWorld feature spike. Without
  press, a niche GPU monitor from an unknown developer plausibly sells
  100–300 copies/year: **$85–$255/yr net at $1** — around or below the
  $99/yr membership that's already sunk.
- **Price and volume are weakly correlated** on the Mac App Store; $1 does
  not buy meaningfully more downloads than $5, it just caps revenue. If the
  decision is ever "charge," the observed utility band is $4.99–$9.99
  (Maccy: $9.99) — same paperwork, 5–10x the per-copy proceeds.
- **The competitive set is free.** Stats, MonitorControl, Ice, Hidden Bar —
  the macOS menu-bar/monitoring category is dominated by free open-source
  tools with donation links. A $1 GPU monitor competes against $0
  alternatives with more features; the only paid survivors (iStat Menus,
  $14.99+) have a decade of brand.
- **US taxes are owed either way, and hobby-scale charging is the annoying
  kind.** Two defensible filings: *hobby income* (Schedule 1 "other income"
  — no 15.3% self-employment tax, but **no deductions**: the $99 fee can't
  offset it) or *business* (Schedule C — deduct the $99 and hardware, but
  self-employment tax on net profit over $400, quarterly-estimate
  bookkeeping). The IRS profit-motive factors (3-of-5-years profit
  presumption, time invested, livelihood dependence) put a $150/yr side
  utility comfortably in hobby territory; either way the accounting overhead
  is disproportionate to the revenue.
- **EU trader status** (public address + phone) triggers at $1 exactly as it
  does at $9.99 — the privacy cost is flat, the revenue is not.
- **Opportunity cost:** for a portfolio/consulting-credibility artifact, a
  free tool with stars and users is worth more than ~$200/yr. Charging
  day-one also suppresses the adoption that would ever justify charging.

**Verdict:** not worth it at launch. The honest fork is *free + donations
now*; *$4.99–9.99 later* if it somehow gets traction — never $1.

## Open source vs closed binary — and the MIT-in-a-private-repo nuance

Current state: `LICENSE` is MIT, repo is private. Two facts resolve most of
the confusion:

1. **A license binds licensees, not the author.** As sole copyright holder
   you are not bound by your own MIT grant — you may ship a closed binary,
   sell it, or relicense at any time. (This ends the moment outside
   contributors land PRs: their code is theirs, MIT-licensed *to* you, and a
   later license change needs their agreement. Decide before going public.)
2. **A private repo's license grants nobody anything.** MIT has no external
   effect until someone receives the code. Shipping only a notarized binary
   while the repo stays private *is* closed-source distribution, and it is
   legally clean — no obligation to publish source ever attaches.

So all doors are open. The realistic postures, best-fit-first for this app:

| Posture | What it looks like | Fit |
|---|---|---|
| **Open source (MIT) + donations** | Public repo, free everywhere, Sponsors/Ko-fi links | The category norm (Stats, MonitorControl, Ice). Max trust — it reads the GPU registry, and the dev audience will check. Max portfolio value. Accepts clone risk (mitigations: publish first, name/trademark — see the licensing note). |
| **Open core, Rectangle model** | Free MIT core app + separate paid closed "Pro" sibling | Proven at scale (Rectangle: 27k+ stars; Pro is a paid closed build on the same foundation). Only relevant if a Pro-worthy feature set ever exists — currently it doesn't. |
| **Maccy model** | MIT source public; identical build sold on MAS for convenience | Compatible with posture 1 later; needs traction first. |
| **Closed binary** | Repo stays private; notarized binary via GitHub Releases/Homebrew | Legally sound, zero clone risk — but for a system-monitoring tool aimed at developers, unverifiable source is a real trust/adoption tax, and it forfeits the portfolio value. Weakest fit. |
| **Source-available (PolyForm NC)** | Source public, resale barred | The middle path if clone-resale genuinely bothers you; costs OSI status and some contributor goodwill. |

The trust point is the decider: a closed-source app whose pitch is "watches
your GPU, collects nothing" asks users to take the "collects nothing" on
faith. Open source makes the privacy claim checkable — which for this
audience is itself a feature.

**Decided 2026-08-07: the first row — open source (MIT) + donations, free in
every channel, no ask inside the binary.** The channels that carry it, and the
order they go live in, are recorded in [DISTRIBUTION.md](DISTRIBUTION.md). The
Maccy row stays available later without contradiction: a public MIT repo costs
nothing legally if charging on the store ever becomes worth the paperwork.

## Sources

Researched 2026-07-20:

- [Apple — App Store Small Business Program](https://developer.apple.com/app-store/small-business-program/)
- [RevenueCat — the 15% App Store fee guide](https://www.revenuecat.com/blog/engineering/small-business-program)
- [Apple — App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/) (3.1.1 tips via IAP; external-link rules)
- [9to5Mac — guidelines updated to allow external payment links (US storefront, May 2025)](https://9to5mac.com/2025/05/01/apple-app-store-guidelines-external-links/)
- [MacRumors — appeals court lets Apple seek fees on external links (Dec 2025)](https://www.macrumors.com/2025/12/11/apple-app-store-fees-external-payment-links/)
- [Robert Baer — Buy Me a Coffee link rejection case study](https://medium.com/@robert-baer/my-ongoing-battle-with-apple-over-a-buy-me-a-coffee-link-is-over-9c158df81c05)
- [Apple — EU DSA trader requirements in App Store Connect](https://developer.apple.com/help/app-store-connect/manage-compliance-information/manage-european-union-digital-services-act-trader-requirements/)
- [MacRumors — public contact details required for EU trader status](https://www.macrumors.com/2024/10/17/developers-eu-app-store-trader-requirements/)
- [Talkspresso — Buy Me a Coffee vs Ko-fi vs Patreon fees (2026)](https://talkspresso.com/blog/buy-me-a-coffee-vs-ko-fi-vs-patreon-2026)
- [donatr.ee — GitHub Sponsors alternatives / donation platforms (2026)](https://donatr.ee/blog/github-sponsors-alternatives/)
- [Maccy](https://maccy.app/) ([GitHub](https://github.com/p0deje/Maccy), [Mac App Store $9.99](https://apps.apple.com/us/app/maccy/id1527619437?mt=12)) — the open-source + paid-MAS reference model
- [Eternal Storms — Selling Outside of the Mac App Store, Part II (Paddle)](https://blog.eternalstorms.at/2024/12/18/selling-outside-of-the-mac-app-store-part-ii-lets-meddle-with-paddle/)
- [Keylight — how to sell an app outside the App Store](https://keylight.dev/sell-app-outside-app-store/)

Added 2026-07-20 (Plan B / $1 analysis / open-vs-closed):

- [IRS — 1099-K threshold reverts to $20,000 + 200 transactions under OBBBA](https://www.irs.gov/newsroom/irs-issues-faqs-on-form-1099-k-threshold-under-the-one-big-beautiful-bill-dollar-limit-reverts-to-20000)
- [IRS — hobby vs business for side hustles](https://www.irs.gov/newsroom/hobby-or-business-what-people-need-to-know-if-they-have-a-side-hustle)
- [Buy Me a Coffee — tax process (no forms from BMAC; Stripe 1099-K at federal threshold)](https://help.buymeacoffee.com/en/articles/8039657-understanding-the-tax-process-on-buy-me-a-coffee)
- [Apple — minimum payment threshold ($10 for US-currency banks, else $150)](https://developer.apple.com/help/app-store-connect/reference/reporting/minimum-payment-threshold/)
- [ProFocus — the 99-cent app problem](https://www.profocustechnology.com/general/99-cent-app-problem/) and a [Mac utility revenue postmortem (Battery Status: ~500 sales at $1.99 + press spike)](https://forums.macrumors.com/threads/how-much-money-you-make.1426425/)
- [Rectangle](https://rectangleapp.com/) ([GitHub, 27k+ stars](https://github.com/rxhanson/rectangle)) — the free-OSS-core + paid-closed-Pro model
- [Ben Balter — open source licensing for maintainers (sole copyright holder may relicense)](https://ben.balter.com/2017/11/28/everything-an-open-source-maintainer-might-need-to-know-about-open-source-licensing/)
- [opensource.guide — the legal side of open source](https://opensource.guide/legal/)
