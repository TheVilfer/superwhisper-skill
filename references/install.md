# Installing the CLI and wiring up the skill

> The agent only explains these steps to the user and checks the state; it does not install anything itself.
> Installation (`curl … | bash`, editing `PATH` or the shell profile) happens only with the user's explicit consent.

## Requirements

- macOS only (the CLI ships as a universal binary for Apple silicon and Intel).
- The **Superwhisper app** is installed and has been launched at least once. Otherwise its database doesn't exist yet and the CLI has nothing to read.
- `jq` for `scripts/transcript.sh`. It ships with macOS (`/usr/bin/jq`); `brew install jq` also works.
- Pro is needed only for `superwhisper transcribe <file>`. Reading history and meetings doesn't need it.

## 1. Check whether it is already installed

```bash
command -v superwhisper || ls -l ~/.local/bin/superwhisper /usr/local/bin/superwhisper 2>/dev/null
superwhisper --version     # superwhisper 0.2.0
superwhisper doctor        # DB path, number of recordings, latest recording, app version
```

If `doctor` shows the database and a non-zero `Recordings`, everything works and no installation is needed.

## 2. Install

```bash
curl -fsSL https://superwhisper.com/install-cli.sh | bash
```

What the script does (checked 04.11.2026): it fetches the latest tag from the GitHub releases of `superultrainc/superwhisper-cli-release`, downloads `superwhisper-<tag>-macos-universal.tar.gz`, verifies the SHA-256 against `checksums.txt` and installs the binary into:
- `/usr/local/bin` if you can write there without sudo;
- otherwise `~/.local/bin`.

Variables:
- `SUPERWHISPER_VERSION=v0.2.0` pins a specific version;
- `SUPERWHISPER_BINDIR=<dir>` sets your own directory.

Without `curl | bash`: download the archive and `checksums.txt` by hand from https://github.com/superultrainc/superwhisper-cli-release/releases, check them with `shasum -a 256 -c`, then `install -m 0755 superwhisper ~/.local/bin/`.

## 3. PATH

If the script printed `note: ~/.local/bin is not on your PATH`, add this to `~/.zshrc`:

```bash
export PATH="$HOME/.local/bin:$PATH"
```

Agent harnesses (Aside, cron, GUI apps) often don't read `~/.zshrc`. That's why the skill calls the binary by its full path `~/.local/bin/superwhisper`, and `transcript.sh` falls back to that path itself. You can also point it somewhere else explicitly: `SUPERWHISPER_BIN=/path/to/superwhisper`.

## 4. Updating

The CLI has no self-update command. Compare versions and run the installer again:

```bash
superwhisper --version
curl -fsSL https://api.github.com/repos/superultrainc/superwhisper-cli-release/releases/latest | grep '"tag_name"'
curl -fsSL https://superwhisper.com/install-cli.sh | bash      # overwrites the binary in the same directory
```

After an update, check that the flags in SKILL.md still work (`superwhisper meetings --help`), and update `references/cli.md` if needed.

## 5. Wiring up the skill

With the `skills` CLI (any supported agent): `npx skills add TheVilfer/superwhisper-skill`.

Or clone once and symlink the folder into each harness, so one `git pull` updates all of them:

```bash
git clone https://github.com/TheVilfer/superwhisper-skill ~/.agents/skills/superwhisper
SKILL=~/.agents/skills/superwhisper
ln -sfn "$SKILL" ~/.claude/skills/superwhisper                             # Claude Code
ln -sfn "$SKILL" ~/.codex/skills/superwhisper                              # Codex
for d in ~/.aside/u/*/skills; do ln -sfn "$SKILL" "$d/superwhisper"; done   # Aside, all profiles
```

Check it: in a new Aside session, ask "what was the last meeting in Superwhisper". The agent should call `superwhisper meetings`.

## Removing it

```bash
rm ~/.local/bin/superwhisper            # or /usr/local/bin/superwhisper
rm ~/.aside/u/*/skills/superwhisper     # removes only the symlinks; the skill folder stays
```

If MCP was ever connected: `superwhisper mcp uninstall`.
