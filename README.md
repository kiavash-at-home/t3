# T3 Code Flatpak

[T3 Code](https://github.com/pingdotgg/t3code) repackaged as a Flatpak from the upstream Debian Package.

## Wayland

T3 Code runs natively on Wayland when launched from a Wayland session. X11 is still
available as a fallback on non-Wayland sessions through Flatpak's `fallback-x11`
socket.

## Graphics acceleration

The sandbox grants `--device=dri` so Electron can use the GPU for page
compositing, rasterization, and animations. Without that permission Electron
can fall back to software rendering, making navigation and animations laggy.


## Preview browser

T3 Code's server-side preview browser (used by `html_preview` and headless
browser tabs) is a downloaded Chrome that normally starts its own sandbox. Inside
Flatpak that fails with "No usable sandbox", and T3 Code then wrongly tells you to
run `t3 browser setup` for AppArmor. The manifest sets
`T3CODE_SERVER_BROWSER_SANDBOX=0` so Chrome runs inside the Flatpak sandbox
without its own inner one.

For an older installation, set it locally and restart T3 Code:

```bash
flatpak override --user --env=T3CODE_SERVER_BROWSER_SANDBOX=0 com.t3tools.t3code
```

## Sandbox runtime tools

The Flatpak bundles sandbox-local `git`, `Antigravity` and `Grok Build` CLIs. These are real binaries inside `/app`, not host wrappers. The launcher does not add host `~/.local/bin` to `PATH`. The manifest does not grant host command execution, access to the rest of the home directory, or SSH-agent access. `~/.t3` is the one host directory it mounts.


When installed normally, those resolve under `~/.var/app/com.t3tools.t3code/data/npm-global` and `~/.var/app/com.t3tools.t3code/cache/npm`.

## Persistent data

Without home directory access, `$HOME` inside the sandbox is a temporary
filesystem that is discarded when T3 Code exits. T3 Code state is the
exception: `~/.t3` is the host directory, so a Flatpak install and a native
install share settings, threads, tokens, and worktrees. Other tool state stays
under `~/.var/app/com.t3tools.t3code`.

| Inside the sandbox | Stored on the host | Contents | Mechanism |
|---|---|---|---|
| `~/.t3` | `~/.t3` | T3 Code settings, keybindings, threads (`state.sqlite`), login tokens, secrets, worktrees | `--filesystem=home/.t3:create` |
| `$XDG_CONFIG_HOME/git/config` | `~/.var/app/com.t3tools.t3code/config/git/config` | `git config --global` settings | launcher creates the file so git prefers it over `~/.gitconfig` |
| `$HISTFILE` | `~/.var/app/com.t3tools.t3code/.local/state/bash/history` | terminal shell history | launcher sets `HISTFILE` |
| `$XDG_CONFIG_HOME`, `$XDG_DATA_HOME`, `$XDG_CACHE_HOME` | `~/.var/app/com.t3tools.t3code/{config,data,cache}` | Electron profile, OpenCode, npm globals and cache | Flatpak default |
| `~/.grok`, `~/.gemini` | `~/.var/app/com.t3tools.t3code/{.grok,.gemini}` | Grok Build and Antigravity CLI state | `--persist=.grok`, `--persist=.gemini` |

`.grok` and `.gemini` stay app-private. Granting the whole `--filesystem=home`
makes Flatpak ignore `--persist` and use the host home directly. The narrower
`home/.t3` grant does not.

Earlier builds stored T3 Code state in `~/.var/app/com.t3tools.t3code/.t3`.
That path is no longer mounted. Quit T3 Code first. If `~/.t3` does not exist
yet, move the old directory once before the first launch of a build that
includes this change:

```bash
mv ~/.var/app/com.t3tools.t3code/.t3 ~/.t3
```

If `~/.t3` already exists from another install, keep it. Copy anything you
still need out of the old Flatpak directory, then remove that directory when
you no longer need the copy.

T3 Code worktrees live at `~/.t3/worktrees` on the host, so host git sees the
same paths the sandbox does.

## Project access

T3 Code's private app data lives under `~/.var/app/com.t3tools.t3code` (see
[Persistent data](#persistent-data)). The
default Flatpak sandbox does not grant access to your repositories.

For persistent access to one project directory, add a narrow user override:

```bash
flatpak override --user --filesystem=/path/to/project:rw com.t3tools.t3code
```

If a project is a symlink whose destination lies outside the granted directory,
grant access to the resolved destination as well. Access to the directory
containing a symlink does not expose an otherwise inaccessible target:

```bash
realpath "$HOME/projects/example"
flatpak override --user --filesystem="$(realpath "$HOME/projects/example"):rw" com.t3tools.t3code
```

Here, `$HOME/projects/example` is the symlink. Keep access to its containing
directory if you want to open the project through that link. The additional
grant covers the resolved destination at the time of the command. If the link
is changed to point elsewhere, review and grant its new destination separately.
Do not grant `home` or `host` just to expose arbitrary symlink targets.

To revoke that project later:

```bash
flatpak override --user --nofilesystem=/path/to/project com.t3tools.t3code
```

For a symlink target grant, revoke the actual destination path that was granted,
even if the link has since changed or been removed:

```bash
flatpak override --user --nofilesystem=/actual/path/to/project com.t3tools.t3code
```

Inspect active permissions with:

```bash
flatpak info --show-permissions com.t3tools.t3code
flatpak override --user --show com.t3tools.t3code
```

Mounted project paths are visible to T3 Code and any sandbox-local tools it runs,
including terminals and provider CLIs. Broad `home` or `host` filesystem grants
are intentionally not recommended.

## Building locally

To build the x86_64 Flatpak bundle locally, install Podman and run the Flathub Flatpak build image from the repository root. The named `t3-flatpak-build` volume keeps Flatpak's SDK, build state, and OSTree repository between runs. The generated bundle is written to `out/t3code.flatpak`.

```bash
make
```

The container needs network access to Flathub and the upstream source hosts. `--privileged` is required by the supplied build image for its Flatpak build setup. `--force-clean` recreates the build directory, while cached downloads and the repository remain in the named volume. To start with a fresh cache and build repository, remove that volume with `docker volume rm t3-flatpak-build` after stopping other builds that use it.

## Contributor credits

[Matěj Cepl (@mcepl)](https://github.com/mcepl) contributed the work in
[#2](https://github.com/0cwa/t3-flatpak/pull/2),
[#4](https://github.com/0cwa/t3-flatpak/pull/4),
[#5](https://github.com/0cwa/t3-flatpak/pull/5),
[#6](https://github.com/0cwa/t3-flatpak/pull/6),
[#7](https://github.com/0cwa/t3-flatpak/pull/7),
[#8](https://github.com/0cwa/t3-flatpak/pull/8),
[#10](https://github.com/0cwa/t3-flatpak/pull/10), and
[#11](https://github.com/0cwa/t3-flatpak/pull/11). Those contributor commits
were preserved when the changes were integrated through
[#13](https://github.com/0cwa/t3-flatpak/pull/13) and
[#15](https://github.com/0cwa/t3-flatpak/pull/15). The related updater fix
in [#16](https://github.com/0cwa/t3-flatpak/pull/16) also includes a
`Co-authored-by` commit trailer crediting Matěj. Three early commits in #2
retain `Unknown` as their original Git author name; this acknowledgement
makes the PR-level attribution explicit without rewriting their history.

The work in #6, #7, and #8 was adapted from earlier **Codefloe** commits,
as documented in those pull requests. Credit for that source work belongs
alongside the contributors who adapted and integrated it.
