# ds_firefox

This repository is a fork of Firefox, imported from Mozilla's official
GitHub repository: https://github.com/mozilla-firefox/firefox

## Upstream origin

| | |
|---|---|
| Upstream repo | https://github.com/mozilla-firefox/firefox |
| Upstream branch | `main` |
| Upstream commit | `86136a5faf970e59063cd07b822717f6fd03a958` |
| Upstream commit date | 2026-10-29T17:14:50+00:00 |

The import is a single squashed root commit containing the full source tree
at that commit. Upstream history is not included (it is tens of gigabytes);
use the upstream repository when you need `git log` or `git blame` on
original Firefox code.

## Changes from upstream

- Automatic application updates are disabled completely. The build is
  configured with `--disable-updater`, which removes the updater binary,
  the update service, and (on Windows) the maintenance service and the
  background update agent. There is no update checking or update UI.

## Building

The GitHub Actions workflow in `.github/workflows/build.yml` builds the
Windows x86_64 package on every push to the default branch and uploads it as
a workflow artifact.

Follow the standard Firefox build docs:
https://firefox-source-docs.mozilla.org/setup/

```bash
./mach bootstrap
./mach build
./mach run
```

## Syncing with upstream

Add upstream as a remote and fetch it shallowly (a full fetch pulls the
entire Firefox history):

```bash
git remote add upstream https://github.com/mozilla-firefox/firefox
git fetch --depth 1 upstream main
```

Because this fork does not share history with upstream, apply upstream
changes as a diff between the recorded upstream commit and the new one, then
update the commit recorded in this file:

```bash
git fetch --depth 1 upstream main
git diff 86136a5faf970e59063cd07b822717f6fd03a958 upstream/main | git apply --3way
```

Alternatively, re-import a fresh snapshot of upstream and reapply local
changes on top of it.
