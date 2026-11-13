# Vision

`welkomscherm` is Dutch for welcome screen, and the promise is deliberately small: a centred handful
of lines, the links you actually use, and nothing that gets in your way — the same buffer in a
graphical frame, in a terminal and over SSH, built from Emacs' own facilities. This document is about
what that promise implies for the next few years: how far the section abstraction should be pushed,
which absences matter, and which constraints are worth refusing to trade.

## Where welkomscherm.el is today

The package is a single file of a few hundred lines, requires Emacs 28.1 and nothing else, and keeps
that claim literally: `cl-lib` and `image` are built in, Org is loaded only when the agenda section is
enabled, and the separators between sections are drawn by the package itself from ordinary text
rather than by a rendering library.

The screen is a list of sections. A section is a `cl-defstruct` with three slots — a name (a string,
a function returning one, or nil), a render function of no arguments, and a condition that decides
visibility — built with `welkomscherm/make-section`. `welkomscherm/render-section` draws the shared
framing: the blank line, the optional separator and the heading. Because the framing is shared, a
section body only ever draws its own content, and adding, removing or reordering a section means
editing `welkomscherm/sections` and nothing else. A bare function of no arguments is still a valid
section, which is how the simplest customisations keep working.

The built-in sections are the banner (opt-in, off by default, and it is Emacs' own splash logo when a
frame can draw one, or nothing, or text art if you ask for it), the top title, the agenda (opt-in,
off by default, read from `org-agenda-files` and rendered one day at a time), work links, bookmarks,
recent files (opt-in, off by default, read from `recentf-list` and skipping files that no longer
exist), actions, system details (opt-in) and startup time. Everything is plain text and ordinary Emacs
buttons. Icons are optional, are plain glyphs rather than an icon font, and fall back to a single
configured substitute when the frame cannot draw the configured one.

Three decisions govern the rest:

1. **Nothing beyond Emacs.** Not an icon package, not a form-feed renderer, not a compatibility shim.
   The separators reflow with the window because the package computes them, and the banner is Emacs'
   own image, so nothing here can break when another package changes.
2. **Sections are the primitive, not widgets.** Dashboards usually offer a fixed menu of widgets with
   a count per widget. This offers the thing widgets are made of, so a section you write is the same
   kind of object as one that ships, and can be reordered, shared or dropped into someone else's
   screen.
3. **Rendering must survive a frame that can draw nothing.** A terminal, a batch Emacs, a font without
   the glyph, an Emacs built without image support: each of those is a case the tests exercise, and
   each has a defined outcome rather than an error.

What is honestly absent: the package is still not in MELPA or ELPA, so installation means fetching a
branch or a recipe; there is no notion of the cost of a section, so a slow recent-files scan and a
constant title look identical in the configuration; the section record has exactly three slots and no
place for metadata a shareable section would want; and there is no answer for a frame that cannot
render the separator character itself.

## The vision

1. **It is installable the way Emacs packages are installed.** An archive entry — MELPA first —
   alongside the four recipes the repository already carries, so "not yet available" stops being the
   first sentence of the installation page.
2. **A section you write is shareable.** A documented, stable section contract with room for metadata
   means sections become a small ecosystem rather than a private list, and somebody else's agenda
   section can be dropped into your screen without a patch.
3. **The screen is honest about cost.** Every section can say what it reads — `recentf`, Org, the
   filesystem, the clock — and the screen either renders instantly or says why it did not. A welcome
   screen that sometimes takes a second is a welcome screen people disable.
4. **It stays legible in fifty years.** No new requirement beyond Emacs, no feature that needs a
   package, no rendering trick that depends on a font or a terminal capability that might disappear.
5. **The same screen is the same screen everywhere.** GUI, terminal, SSH, batch render, forced
   colours, a light or a dark frame — without configuration, because the default path is the one that
   cannot fail.

## Features that are in scope and not built yet

- **An archive recipe.** The README says in two places that the package is not in MELPA or ELPA, and
  the quality gate those archives ask for — byte-compilation with warnings as errors, `checkdoc`, an
  ERT suite — already runs in CI. The hard part is not the recipe but the maintenance promise that
  comes with it.
- **Section metadata.** The struct has name, render and condition, and a shareable section will want
  to declare what it reads and how expensive it is. The hard part is adding slots while keeping "a
  bare function is a valid section" and not breaking every configuration that stores the built-in
  section variables.
- **A cost-free recent-files section.** `recentf-list` is read and filtered at render time. The hard
  part is bounding the filesystem check per render without a cache that goes stale in a way the user
  cannot see.
- **Agenda breadth.** `welkomscherm/agenda-days` draws each entry on its day. The hard part is a
  multi-day layout that stays readable at 80 columns, which is the width that matters.
- **Icon fallbacks.** `welkomscherm/icon-fallback` is a single glyph. The hard part is a fallback
  chain — several candidates, then a plain marker — that is still plain text and still one option.
- **Separator portability.** `welkomscherm/separator` is one character. The hard part is a fallback
  set chosen from what the frame can actually display, plus a test on a non-UTF-8 terminal coding
  system.
- **Nested link lists documented as a contract.** `welkomscherm/bookmarks-list` accepts nested lists
  today and the shape is only explained by example. The hard part is validating it at render time and
  saying what was wrong, rather than drawing something surprising.

## New features that would be worth having

- **A projects section from `project.el`.** Built in, already the canonical list of what a person is
  working on, and a natural companion to work links and bookmarks — provided it stays inside the
  "reads nothing expensive" rule.
- **A clock and calendar section.** The manual already shows a one-line example with
  `format-time-string`, which is an admission that this belongs in the package as a proper section.
- **A section preview command.** Render one section into a temporary buffer, so writing a section does
  not mean restarting Emacs to look at it.
- **A section-author macro.** `welkomscherm-insert` that wraps the drawing helpers — muted text,
  separator, centring, rows — so a third-party section is four lines rather than twelve.
- **A session-aware greeting.** Time of day, plus the last session's date from `savehist`, because a
  welcome screen that knows it is Monday is warmer than one that does not.
- **Per-section separators.** A section that wants a rule above it and one that does not are both
  reasonable, and today the choice is global.
- **A plain-text screen export.** The repository already renders the real buffer into screenshots; the
  same path could write a text file for documentation, a README or a paste.
- **A startup-budget report.** Measure each section's render time in a batch Emacs and print it, so
  the "renders instantly" claim becomes a number in CI rather than an intention.

## Contributions that would move the needle

1. **The archive recipe.** Highest value per hour in the whole project: the gate exists, the package
   is small and checkdoc-clean, and an archive entry is what turns "clone this branch" into
   "install it".
2. **A documented startup recipe.** `initial-buffer-choice`, `savehist` for the chosen sections and a
   note on why the buffer is not the scratch buffer — the installation page is halfway there.
3. **Two example sections in the manual** that look like something a stranger would write, including
   the metadata they should declare. Documentation is what makes an abstraction adoptable.
4. **A projects section from `project.el`,** which is the most requested kind of block in every
   dashboard and the cheapest one here.
5. **Per-section separators and separators that survive a narrow frame,** because the current global
   switch is the first thing people want to bend.
6. **Tests for narrow frames and non-UTF-8 terminals.** The suite already covers frames that can draw
   nothing; 40 columns and a terminal coding system are the next two honest edges.
7. **A render-time benchmark in CI.** It protects the one promise that is hard to notice breaking.

## Compared to related projects

| Project | What it is | Where welkomscherm differs |
| --- | --- | --- |
| `emacs-dashboard` | The richest Emacs dashboard: banner, recent files, bookmarks, projects, agenda and registers, configured through `dashboard-items` and `dashboard-startupify-list` | It is a cockpit and a good one, with several times the code and optional integrations. welkomscherm offers one screen, a section abstraction instead of a widget menu, and no dependency at all. |
| `enlight` | A small framework (~330 lines) where you supply the whole content as a string, with optional text menus | Enlight is a content hook; this is a structure of composable sections. Enlight's freedom is total, and its only external dependency is `compat`. |
| `welcome.el` | A compact welcome buffer (~277 lines) built around a key-driven command menu, needing `nerd-icons` | welcome.el is a launcher: press a key, run a command. welkomscherm is a page of links with no key map of its own beyond navigation. |
| `minimal-dashboard.el` | A dashboard narrowed to a centred image and a line of text (~337 lines) | The most restrained of the group, and the closest to this package's aesthetic. It has no section model, so everything beyond the image is your own code. |
| Doom Emacs' dashboard module | Doom's own splash: banner art, menu, configurable sections, bound to Doom's packaging and theming | Deeply integrated and pleasant if you run Doom, and inseparable from it. welkomscherm runs on stock Emacs with no configuration framework. |
| Vanilla Emacs' startup screen | The `*GNU Emacs*` splash: logo, tutorial links, a copy of the GNU Manifesto | The baseline this package is a deliberate improvement on: the same idea, centred, with the links a person actually uses, and no manual page about the philosophy of Emacs. |

What the others do that welkomscherm could still add: emacs-dashboard's widget vocabulary, including
projects and registers, and its `dashboard-startupify-list` trick of listing only the items you have;
enlight's total freedom over content; welcome.el's command menu with key bindings; doom's banner art
and its section registry; and the vanilla splash's guarantee that nothing it draws can ever fail.
Where welkomscherm is ahead and should stay ahead: zero external dependencies with no optional
integration hiding in `Package-Requires`; sections as the primitive, so the built-in blocks and your
own are the same kind of object; one configuration that renders identically in a GUI frame, a terminal
and over SSH, with a defined outcome when a frame can draw nothing; separators computed from the
window width instead of drawn by a helper package; and screenshots generated from the package's own
buffer output, so the pictures in the README cannot drift from the code.

## In the long run

The multi-year bets are about restraint as a feature. The first is that **zero dependencies is an
architectural decision, not a limitation**: it is why the package can be recommended to someone
debugging their init file, vendored into a configuration, or read in full before installing, and every
future feature has to earn its place against that. The second is that **sections become a shared
vocabulary**: if the contract is documented and stable, the interesting work moves out of this
repository and into other people's configurations, and the package's job becomes keeping the framing
and the primitives honest. The third is that **the screen stays text**: the one image is Emacs' own
logo, the icons are glyphs with fallbacks, and everything else is characters in a buffer — which is
what makes the same code correct on a laptop, a workstation and a server console. The fourth is that
**it should still work when nobody has touched it for years**, which is a testable property: a batch
render, a narrow frame, a terminal without glyphs, and a render-time budget in CI.

## What this document is for

Use it to place a proposal. A new section that reads something cheap and draws it with the existing
helpers is always welcome; a new dependency, a rendering trick that needs a font, or a feature that
only works in a graphical frame is not. Anything that makes the section contract clearer, the default
screen calmer, or the installation shorter is the work this package is for.

*This document describes intent, not commitments; the code, the release notes and the issue tracker
say what is actually true today.*
