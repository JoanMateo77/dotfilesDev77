# dots: reproducible dev environment with Nix and a Go TUI

> **Origin.** This repository is based on
> [sanurb/.dotfiles](https://github.com/sanurb/.dotfiles) by David Urbano
> (MIT, see [LICENSE](./LICENSE)). The `dots` CLI, the Nix and Home Manager
> modules, and the CI and release pipeline are his work. I use it as my own
> development environment on macOS (Apple Silicon); my changes are listed in
> [What I changed](#what-i-changed).

Interactive frontend for a Nix-managed personal environment. The Go binary is
the user-facing layer; Moon + Nix + Home Manager are the deterministic
backend. `dots` never mutates `~/` directly — it scans, prompts, and delegates
to `moon run modules:<task>`.

**Who it is for:** developers on macOS or Linux who want to pick their shell,
terminal, font, multiplexer and editor once in a wizard, and get the same
environment on every machine, with a plan they can review before applying and
a rollback to the previous Home Manager generation.

**Stack:** Go 1.26 with Bubble Tea, Bubbles and Lip Gloss (TUI) · Nix flakes,
Home Manager and devenv · Moon 1.40 and proto (tasks and pinned runtimes, see
`.prototools`) · GoReleaser with cosign keyless signing · Renovate · GitHub
Actions (`.github/workflows/`).

## What I changed

- **Install notes from a fresh Apple Silicon Mac**
  ([docs/personal-setup.md](./docs/personal-setup.md), in Spanish): Determinate
  Nix `trusted-users` so binary caches are used, Nix paths for Fish launched
  from a GUI terminal, Starship after direnv activates the dev shell, and a
  `dots doctor` false positive for Ghostty on macOS.
- **Shell prompt:** a Fish hook that re-runs `starship init` on prompt
  (`config/fish/conf.d/starship.fish`) and a custom prompt glyph
  (`config/starship/starship.toml`).

## Installation

The install channels below (Homebrew tap, curl script and `nix run`) are the
upstream ones and install the upstream `dots` release.

`dots` is two components: a TUI binary that writes a profile, and a Nix
flake + Home Manager modules that realize the profile into `$HOME`. The
TUI runs anywhere a Go binary runs; realization needs Nix and a clone of
this repo. There are three peer install paths — Homebrew, curl, and
`nix run` — pick the one that matches how you already get tools.

> **Supported platforms:** macOS and Linux. The realization layer
> depends on `nh` and Moon, neither of which has a Windows port; the
> TUI binary similarly does not ship for Windows. Windows users need
> WSL2 — both the TUI and `dots deploy` work inside it.

### Homebrew

```sh
brew install sanurb/tap/dots
```

Persistent binary at `$(brew --prefix)/bin/dots`. The tap
([sanurb/homebrew-tap][tap]) ships only `dots`; auto-bumps on every
release.

### Curl

```sh
curl -fsSL https://raw.githubusercontent.com/sanurb/.dotfiles/main/scripts/install.sh | sh
```

Persistent binary at `~/.local/bin/dots` (override with `INSTALL_DIR=`).
The fetcher is POSIX `sh`, downloads the stable raw-binary asset
(`dots-{darwin,linux}-{amd64,arm64}`), always verifies SHA-256, and
verifies the cosign keyless OIDC signature when `cosign` is on `$PATH`.

### `nix run`

```sh
nix run github:sanurb/.dotfiles -- install
```

Ephemeral execution — no persistent install. Requires Nix on the host
already; no clone required (Nix fetches the flake on demand).

### After install

```sh
dots                  # bare invocation runs the init wizard
dots init             # explicit; same as bare `dots` (alias: install)
dots plan             # show what `dots apply` would do — a saved plan can be
dots plan --out p.json #   reviewed in CI and replayed with --plan
dots apply            # realize the profile (alias: deploy)
dots status           # profile + workspace + last-applied receipt
dots update           # git pull --ff-only && dots apply
dots rollback         # switch Home Manager to the prior generation
```

`dots init` is the unified entry point. On a fresh machine it
self-bootstraps Nix and the workspace clone behind per-prereq consent
prompts, runs the wizard against the cloned
workspace, then offers to realize. No intermediate artifact, no manual
follow-up steps. Every state-mutating command is shown verbatim before
it runs.

The verb grammar groups every subcommand by side-effect
class: **converge** (init, apply, update, rollback, sync), **measure**
(status, plan, diff, doctor, why, explain, scan), and **power-user**
(capture, profile, completion, backup). Run `dots help` for the full
table or `dots help <verb>` for per-verb summary. `dots explain plan`
documents the plan/apply contract; `dots explain exit-codes` documents
the stable exit-code table.

For the canonical day-to-day UX, install [direnv][] so that entering
the cloned workspace activates the dev shell automatically; `dots
apply` then runs without a `nix develop -c` prefix.

## Verifying a release

Every release archive and the `SHA256SUMS` file are signed with cosign using
keyless OIDC (no managed keys; the certificate identity is the GitHub Actions
workflow). The verification recipe is in
[RELEASING.md](./RELEASING.md#verifying-a-downloaded-release) and embedded in
each GitHub Release's notes.

## Development

The dev shell is fully declarative — entering the directory provisions every
runtime, language server, and release tool:

```sh
direnv allow   # one-time
# everything below works inside the shell that direnv just activated
moon run cli:check
moon run cli:test
dots plan          # see what apply would do
dots apply         # realize the workspace
```

See `DESIGN.md` for the architecture and `devenv.nix` for the declared
toolchain.

---

Maintained by [Joan Mateo Cardona](https://github.com/JoanMateo77), based on
[sanurb/.dotfiles](https://github.com/sanurb/.dotfiles) by David Urbano.

[direnv]: https://direnv.net/
[tap]: https://github.com/sanurb/homebrew-tap
