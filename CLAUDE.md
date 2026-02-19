# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

A Hugo static blog deployed to GitHub Pages via GitHub Actions. The theme is `m10c` (git submodule). Pushes to `master` trigger CI that lints then builds and deploys.

## Setup

```bash
mise install          # installs hugo-extended 0.140.1, gitleaks, shellcheck, pre-commit
mise x -- pre-commit install  # installs git hooks
```

## Commands

- **Local preview**: `./preview.sh` (runs `hugo server --buildDrafts`)
- **New post**: `./new_post.sh` (interactive: fzf for category/tags, prompts for title, opens `$EDITOR`)
- **Build**: `hugo --minify`
- **Run hooks manually**: `mise x -- pre-commit run --all-files`

## Content structure

Posts live in `content/post/<category>/Title.md`. Current categories: `bash`, `crafting`, `devops`, `homelab`, `productivity`.

Post front matter:
```yaml
---
title: "Post title"
date: 2024-01-01T10:00:00+01:00
tags: ["tag1", "tag2"]
categories: ["category"]
draft: true
---
```

Set `draft: false` to publish. Static assets go in `static/` and are referenced without the `/static/` prefix.

## Pre-commit hooks

Hooks run automatically on commit and in CI (`lint` job):
- `trailing-whitespace`, `end-of-file-fixer` — on markdown and toml
- `check-added-large-files` — blocks files >2MB
- `check-merge-conflict`
- `gitleaks` — secret detection
- `shellcheck` — lints `*.sh` files (excludes `themes/`)
- `hooks/hugo-build-check.sh` — full Hugo build with `--renderToMemory`
- `hooks/frontmatter-lint.sh` — validates `title`, `date`, `categories` in post front matter
- `hooks/static-asset-check.sh` — validates `src="/"` image paths exist in `static/`

## CI / branch protection

The `lint` job runs on all PRs and push to master. `build` and `deploy` only run on master after lint passes.

To require PRs on GitHub: Settings → Branches → Add rule for `master` → enable "Require status checks to pass" (select `lint`) and "Require a pull request before merging".

## Custom styling

`assets/css/_extra.scss` is the only custom CSS, loaded on top of the m10c theme.
