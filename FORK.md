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

## Silent updates

Builds update themselves from this repository's GitHub releases, without any
notification, badge or prompt. Changes from upstream:

- `app.update.silent` (default `true`) suppresses every update notification.
  Updates are still checked, downloaded and staged in the background, and the
  new version starts on the next restart. Set it to `false` in `about:config`
  to get the normal notifications back.
- The update URL is set with the `--with-app-update-url` configure option and
  points at `update.xml` in the latest release.
- Update packages (MARs) are signed with this fork's own key. The updater
  only trusts `toolkit/mozapps/update/updater/ds_firefox_primary.der`, so it
  can never install a stock Mozilla build over this fork.
- The maintenance service is not built, because it only accepts updaters
  signed by Mozilla. Install into a folder your user account can write to,
  such as `%LOCALAPPDATA%\ds_firefox`, so updates never need an admin prompt.
- The background update agent may update unelevated installs, so updates are
  also applied while the browser is closed.

### One-time setup

1. Add the update signing private key (PEM) as the repository secret
   `MAR_SIGNING_KEY`. Keep an offline backup: installed builds only accept
   updates signed with this key.
2. Release downloads must be reachable without logging in. Either make this
   repository public, or set the repository variable `RELEASE_REPO` to a
   public repository and add a `RELEASE_TOKEN` secret that can create releases
   there. The update URL is baked in at build time from `RELEASE_REPO`.

Each push then builds Windows x86_64, signs a complete update package, and
publishes a release with the zip, installer, update package and `update.xml`.
Installed builds pick it up within a day.

## Building

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
