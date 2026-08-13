# Maintainer Release Process

[中文说明](../cn/maintainer-release.md)

This document is for `mpc-frame` maintainers. It is excluded from the public
user site and User Kit distribution.

## Repository Settings

Enable read/write workflow permissions under GitHub
`Settings > Actions > General`. Configure Pages to use GitHub Actions. The
`release/user-kit` branch must allow force updates from the User Kit workflow;
it does not need to be created manually.

## Pre-Merge Validation

```sh
make -f Makefile.dev docs-check
make -f Makefile.dev stage9-test
make -f Makefile.dev regression-fast
make -f Makefile.dev reference-test
make -f Makefile.dev docs-site-check
make -f Makefile.dev export-user-kit
```

Run `doctor`, `create`, `check`, `trace`, and `wave` inside `build/user-kit`, and
verify that the generated FST is non-empty. This confirms that the exported
distribution and waveform workflow do not depend on maintainer content. After
the smoke test, export a fresh clean User Kit and verify that it contains no
`build/` directory or smoke design.

## Publication Chain

After merging and pushing to `main`:

```text
CI                     -> source, Frame, and reference regressions
Documentation Pages    -> only pages allowed by dev/site-docs.json
User Kit               -> export, test, and replace release/user-kit
```

The User Kit workflow also uploads an `mpc-frame-user-kit` artifact retained
for 14 days.

## Publication Boundaries

- `dev/site-docs.json` is the public site page allowlist.
- `dev/user-kit.json` is the User Kit file allowlist. Public documentation is
  sourced directly from `dev/site-docs.json`, so new maintainer documents are
  not published accidentally.
- `docs/cn` and `docs/en` contain all bilingual sources, including private
  maintainer material.
- `dev/site` contains only theme, configuration, and static assets.

After changing either allowlist, run `docs-site-check` and the exported-kit
smoke test. The export step deliberately resets `designs/registry.json`,
`rtl/generated/FrameDesignRegistry.sv`, and `rtl/generated/user-designs.f` to a
design-0-only blank frame, so maintainer-integrated user RTL is never included
in the public User Kit.

## Import a User Design

Users deliver one `designs/<name>/` package. After review, run:

```sh
make -f Makefile.dev integrate-design \
  DESIGN=designs/<name> DESIGN_ID=<1..127>
make -f Makefile.dev regression-fast
make -f Makefile.dev reference-test
```

Formal integration is transactional: registry validation, generated RTL, and the
Frame test run against temporary files under `build/`. The permanent registry,
`rtl/generated/FrameDesignRegistry.sv`, and `rtl/generated/user-designs.f` are
replaced only after every check passes. A failed integration leaves all three
permanent files unchanged.

Do not require users to edit the permanent registry or select a final ID.

The 128-slot limit applies to the aggregate maintainer FrameTop. It is not a
requirement for an individual User Kit contributor: each contribution is one
design package, and maintainers combine packages into the shared registry.

## Known Limitation

`release/user-kit` is currently a generated orphan branch. It is suitable for
distribution, but users cannot open a normal PR from it to `main`. If direct PR
contribution becomes the primary workflow, use a separate template repository
with an import process or redesign the distribution to preserve shared history.
