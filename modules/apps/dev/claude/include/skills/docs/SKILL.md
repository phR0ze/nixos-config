---
name: docs
description: Use whenever the user types "/docs", regardless of current working directory.
---

# Docs skill

The user's personal technical knowledge base lives at `~/Projects/tech-docs` (built with
[mdBook](https://rust-lang.github.io/mdBook/)), regardless of what directory this skill is invoked
from. Treat "/docs" as referring to that repo. Do not assume the shell's cwd is inside the repo.

## First step, always

Read `~/Projects/tech-docs/CLAUDE.md` before making any change. It is the
source of truth for this repo's page structure, heading conventions, logo
path depth, Quick links / Linked pages rules, and its "Citing File
References" and "Link Validation" rules. Follow it exactly — this skill only
adds the workflow on top of it; if the two conflict, `CLAUDE.md` wins.

## Mental model

- Content lives under `src/<topic>/.../README.md` (or `.md` for leaf pages without children).
- `src/SUMMARY.md` is the single source of truth for the table of contents. **A page that
  exists as a file but isn't listed in `src/SUMMARY.md` is effectively invisible** — it won't
  render in the built book's sidebar/nav.

## When answering "where do my docs cover X" / finding things

1. Search `src/SUMMARY.md` first for the topic/keyword — it's a fast map of everything that
   exists and where it's nested.
2. If not found there, grep `src/**/*.md` content directly (SUMMARY.md only has titles/links,
   not body text).
3. Per `CLAUDE.md`'s "Citing File References" rule, print the file path (or
   `path:line`) of anything you read before relying on it in your answer.

## When adding a new page

1. Create the file at `~/Projects/tech-docs/src/<topic>/<subtopic>/README.md`.
2. Follow the Page Structure Convention in `CLAUDE.md` (logo path depth, Quick links block,
   Linked pages block, heading levels).
3. **Add an entry to `src/SUMMARY.md`** at the correct indentation/nesting level so it appears
   in the sidebar. Match the surrounding style:
   - Top-level sections are `- [Title](topic/README.md)` with a blank line before/after the
     section block.
   - Nested pages indent two spaces per level, e.g. `  - [Sub](topic/sub/README.md)`,
     `    - [SubSub](topic/sub/subsub/README.md)`.
   - A brand-new top-level topic needs its own top-level entry before its children are added.
4. If the new page has a parent `README.md`, add it there too under that parent's
   `### Linked pages` block (per `CLAUDE.md`), and reference it from `### Quick links` if it's
   a same-file anchor.

## When updating an existing page

1. Locate the file (see "finding things" above) and cite it before editing.
2. Apply the edit.
3. If headings changed (added/removed/renamed `##`/`###`), update that page's own
   `### Quick links` block to match — see `CLAUDE.md`'s "Keeping Quick Links Current" section.
4. **SUMMARY.md only needs an update if the page's title changed or the file moved/was
   renamed/deleted** — plain content edits within an existing page don't require touching
   SUMMARY.md.

## When moving, renaming, or deleting a page

- Update (or remove) its entry in `src/SUMMARY.md` to match.
- Update any `### Linked pages` references to it in sibling/parent pages.
- Grep the repo for other pages linking to the old path and fix those links too.

## Verification

After any structural change (new page, moved/renamed/deleted page, or SUMMARY.md edit), run
from inside the repo:

```bash
cd ~/Projects/tech-docs && mdbook build
```

to confirm it builds without broken-link or missing-file errors. `mdbook test` can also be used
to check for broken links specifically.
