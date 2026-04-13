# mdbook Refactor

This branch (`mdbook-refactor`) is the long-lived integration branch for the incremental
migration of the ZIPs rendering pipeline to [mdbook](https://rust-lang.github.io/mdBook/).

## Goal

Merge a series of bite-sized PRs here, each moving one step closer to the end state:

- `mdbook build` builds all ZIPs into a single book
- The book can also be built with `nix flake`
- No render artifacts committed to git
- ToC organized by Category → Status → ZIP

## Steps

1. **Add mdbook scaffolding** ← *first PR, already open*
2. RST → Markdown conversion build script (all ZIPs in the book)
3. Dynamic `SUMMARY.md` generation (Category → Status → ZIP hierarchy)
4. Front page generated from `README.template` / `makeindex.sh`
5. Nix flake integration
6. Remove committed render artifacts from git tracking
7. (Bonus) GitHub Actions CI to publish to GitHub Pages
8. (Bonus) Integrate protocol spec as a book chapter
