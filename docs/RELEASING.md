# Releasing

Running `make test` locally needs `make`, `bash` and Lua 5.1 (WSL or Git Bash on Windows). You can skip that: CI runs
the same checks on every push.

Everything below runs from a tag. A tag that disagrees with `Whereabouts.toc` is refused before anything is published.

## One-time: GitHub
Needs `git` and the GitHub CLI (`gh`), logged in once with `gh auth login`. These lines work as written in
PowerShell, cmd and bash. There is no `<owner>` to fill in: `gh` creates the repository under the account you
logged in with. Each command is on its own line because `&&` does not work in Windows PowerShell 5.1.
```
cd Whereabouts
git init -b main
git add -A
git commit -m "Whereabouts 0.3.0"
gh repo create Whereabouts --public --source=. --remote=origin --push
```
`--push` needs at least one commit, which is why the commit comes first. Do not type angle brackets (`<` `>`)
anywhere: PowerShell reserves them.

Then in the repository settings:
- Rules > Rulesets > new branch ruleset for `main`: require a pull request, and require these status checks:
  `Lint and test`, `Build the player zip`, `Packager dry run`.
- Security > enable "Private vulnerability reporting" (`SECURITY.md` points to it).
- Actions > General > Workflow permissions: the release job asks for `contents: write` itself. Only change this
  if a release fails with a 403.

Then point the in-game update notice at the releases page: set `Version.UPDATE_URL` in `Version.lua` to
`https://github.com/YOUR-USERNAME/Whereabouts/releases/latest` (your real username), and release a patch.

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
Nothing publishes there until both of these exist, so tags work before you are ready.
1. Create the addon project on CurseForge and note its Project ID ("About Project" box).
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
- Not yet tried: an actual upload to CurseForge, and whether CurseForge needs the first file uploaded by hand
  for a new project. Both are untested.
- A third-party report says Forever loads `_Camelot.toc` ahead of an unsuffixed TOC. Whereabouts ships one
  unsuffixed `.toc`; add `Whereabouts_Camelot.toc` only if a future non-Forever client needs a different TOC.

## Hardening you may want later
- Pin third-party actions (`BigWigsMods/packager`) to a full commit SHA instead of `@v2`. Dependabot is set up to
  propose updates for them weekly.
