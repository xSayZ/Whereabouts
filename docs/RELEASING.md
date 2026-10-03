# Releasing

Running `make test` locally needs `make`, `bash` and Lua 5.1 (WSL or Git Bash on Windows). You can skip that: CI runs
the same checks on every push.

Everything below runs from a tag. A tag that disagrees with `Whereabouts.toc` is refused before anything is published.

## One-time: GitHub
You need `git`. The GitHub CLI (`gh`) is optional; only the first-time repository creation can use it, and the release
workflow brings its own. These lines work as written in PowerShell, cmd and bash, one command per line because
`&&` does not work in Windows PowerShell 5.1. Never type angle brackets (`<` `>`): PowerShell reserves them.

**Without `gh`:** create an empty public repository named `Whereabouts` at https://github.com/new (leave "Add a
README", ".gitignore" and "license" unchecked), then:
```
cd Whereabouts
git init -b main
git add -A
git commit -m "Whereabouts 0.3.0"
git remote add origin https://github.com/xSayZ/Whereabouts.git
git push -u origin main
```
Git for Windows normally opens a browser sign-in on the first push. (Done for xSayZ/Whereabouts.)

**With `gh`:** `winget install --id GitHub.cli`, reopen the terminal, run `gh auth login`, then after the commit:
```
gh repo create Whereabouts --public --source=. --remote=origin --push
```
`--push` needs at least one commit.

Then in the repository settings:
- Rules > Rulesets > new branch ruleset for `main`: require a pull request, and require these status checks:
  `Lint and test`, `Build the player zip`, `Packager dry run`.
- Security > enable "Private vulnerability reporting" (`SECURITY.md` points to it).
- Actions > General > Workflow permissions: the release job asks for `contents: write` itself. Only change this
  if a release fails with a 403.

The in-game update notice already points at `https://github.com/xSayZ/Whereabouts/releases` (`Version.UPDATE_URL`). It is the list,
not `/releases/latest`, because GitHub's "latest" skips pre-releases and returns 404 while every release is one (all 0.x are).
When CurseForge is live you may prefer to point it there instead; that is a one-line change and needs a release.

## Every release
1. Bump `## Version` in `Whereabouts.toc` (the only place). Add the matching `## [x.y.z] - date` entry to `CHANGELOG.md`.
2. `make test`, then commit and merge to `main`. CI must be green.
3. Tag and push. With `make` (Linux, macOS, WSL, Git Bash): `make tag`, then `git push origin main vX.Y.Z`.
   Without `make` (plain Windows), run these two lines; the Release workflow does the same checks on GitHub:
```
git tag -a v0.3.0 -m "Whereabouts 0.3.0"
git push origin main v0.3.0
```
4. The Release workflow: verifies the tag, lints, tests, builds `Whereabouts-X.Y.Z.zip`, and creates the GitHub
   release with that changelog section as the notes. Below 1.0.0, or for an `-alpha.N` / `-beta.N` tag, it is
   marked pre-release.

Tags: `vX.Y.Z`, `vX.Y.Z-alpha.N`, `vX.Y.Z-beta.N`. The part before the dash must equal the TOC version.
CurseForge takes the release type (alpha, beta, release) from the tag name.

## One-time: CurseForge
CurseForge keeps a new project "awaiting moderator approval" until a file is uploaded to it (their guide: "Creating and
Submitting a Project"). So the first file goes up by hand; automation takes over afterwards.

**First file, by hand**
1. Create the project on CurseForge and fill in the description (see the README) and licence (MIT).
2. Tag a release as usual and download the asset `Whereabouts-X.Y.Z.zip` from the GitHub release. That is the player
   zip: one root folder `Whereabouts/` containing `Whereabouts.toc`. CurseForge requires the root folder name to match the
   `.toc` name, and `scripts/check-zip.sh` enforces exactly that on every build.
3. Project dashboard > Files > Upload file: pick the `.zip` (it must really be a zip), a display name, release type
   **Release**, and the supported game version (the Forever version, 1.60.1, if the list offers it). Paste the changelog
   section from the release notes.
4. The file shows "Under Review" until a moderator approves it. CurseForge also states that a project needs at least one
   **Release**-type file before it syncs to the CurseForge app, and an addon must be tagged with at least one game version.

**Automatic uploads afterwards** (nothing publishes there until both exist, so tags work before you are ready)
1. Note the project's ID ("About Project" box).
2. Create an API token at https://www.curseforge.com/account/api-tokens.
3. In the GitHub repository: Settings > Secrets and variables > Actions.
   - Secret `CF_API_KEY` = the token.
   - Variable `CURSEFORGE_PROJECT_ID` = the project ID.
   - Optional variable `PACKAGER_ARGS` = extra packager flags, for example `-g forever`.
4. Tag as usual. The `CurseForge` job runs after the GitHub release and uploads the same tag.

If `CURSEFORGE_PROJECT_ID` is set but `CF_API_KEY` is missing, the job fails with a clear message instead of skipping.
A failed upload does not undo the GitHub release; fix the cause and use "Re-run failed jobs".

## What was checked about Forever
Run on 2026-10-03 against BigWigs `release.sh` (master) on this repository, dry run:
- It detects `Build type: non-retail version-forever` and `Game version: 1.60.1` from `## Interface: 16001`
  with no extra flags. Its source maps any `16???` interface to the `forever` game type and accepts `-g forever`.
- It packages exactly the runtime files; `.pkgmeta` ignores everything else. The CI job "Packager dry run" repeats
  this on every change and fails if the zip is not named `-forever`.
- Not yet tried: an upload through the CurseForge API (the packager job). The first file by hand is CurseForge's
  documented route for a new project.
- A third-party report says Forever loads `_Camelot.toc` ahead of an unsuffixed TOC. Whereabouts ships one
  unsuffixed `.toc`; add `Whereabouts_Camelot.toc` only if a future non-Forever client needs a different TOC.

## What the downloads contain
- `Whereabouts-X.Y.Z.zip` (the asset the workflow attaches, and what CurseForge gets): runtime files only.
- GitHub also adds "Source code (zip)" and "(tar.gz)" to every release; they cannot be switched off. Since 0.3.1 they
  honour `export-ignore` in `.gitattributes`, so they omit tests, docs and CI files too. Several projects report that
  GitHub honours this; I have not seen it in GitHub's own documentation, so check the first release after 0.3.1.
  Archives of tags made before the rule existed (v0.3.0) still contain everything.
- A `git clone` is the full repository by design.

## Hardening you may want later
- Pin third-party actions (`BigWigsMods/packager`) to a full commit SHA instead of `@v2`. Dependabot is set up to
  propose updates for them weekly.
