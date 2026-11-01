# ds_firefox

This repository is a fork of Firefox, imported from Mozilla's official
GitHub repository: https://github.com/mozilla-firefox/firefox

## Upstream origin

This fork tracks stable Firefox releases from
https://github.com/mozilla-firefox/firefox. The release it is currently based
on is recorded in `tools/ds_firefox/upstream.env` (tag and commit).

Upstream history is not included (it is tens of gigabytes); use the upstream
repository when you need `git log` or `git blame` on original Firefox code.

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
publishes a release with the installer, update package and `update.xml`.
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

The `Sync with upstream Firefox` workflow runs daily. When Mozilla publishes a
newer stable release tag (`FIREFOX_<version>_RELEASE`), it:

1. Takes the fork's changes, which are everything that differs between the
   recorded upstream commit and this branch.
2. Replaces the source tree with the new release and re-applies those changes
   with a 3-way merge.
3. Commits and pushes the result, then starts the Windows build, which
   publishes the installer (and the signed update) as a release.

If the fork's changes no longer apply cleanly, the workflow fails and lists the
conflicting files; GitHub emails you about the failed run. Resolve it locally
with the same script:

```bash
tools/ds_firefox/sync-upstream.sh
```

`--check` only reports whether a newer release exists, and `--tag <tag>` syncs
to a specific release tag. The workflow can also be started by hand from the
Actions tab.
