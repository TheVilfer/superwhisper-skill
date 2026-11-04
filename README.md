<div align="center">

# superwhisper-skill

**Let your AI agent read your Superwhisper meetings and dictations: locally, read-only, without wasting context.**

[![CI](https://img.shields.io/github/actions/workflow/status/TheVilfer/superwhisper-skill/ci.yml?branch=main&label=ci&style=flat&colorA=000000&colorB=000000)](https://github.com/TheVilfer/superwhisper-skill/actions/workflows/ci.yml)
[![license](https://img.shields.io/badge/license-MIT-000000?style=flat&colorA=000000&colorB=000000)](LICENSE)
[![platform](https://img.shields.io/badge/macOS-000000?style=flat&colorA=000000&colorB=000000&logo=apple)](#requirements)

<a href="#install">Install</a> · <a href="SKILL.md">Skill</a> · <a href="references/cli.md">CLI reference</a> · <a href="README.ru.md">Русский</a>

</div>

An [Agent Skill](https://agentskills.io) for Claude Code, Codex, Aside, Cursor, OpenCode, pi and any other agent with a shell. It teaches the agent to answer questions like *"what did we decide about pricing on Tuesday's call?"* from your [Superwhisper](https://superwhisper.com) recordings through the official local `superwhisper` CLI.

> Unofficial community project, not affiliated with Superwhisper / superultra inc.

## Why a skill and not just the MCP server

Superwhisper ships an MCP server (`superwhisper mcp`), and it works. This skill adds the parts an agent gets wrong on its own:

- **Context budget.** A raw transcript is word-level JSON, ~250 KB for 20 minutes. `scripts/transcript.sh` merges it into speaker turns (~25× smaller), cuts time windows (`--from 12:00 --to 15:00`) and short grep-able lines (`--split 15`).
- **Whisper hallucinations.** On silence Whisper invents "Thanks for watching!", "Subtitles by the Amara.org community", or "Продолжение следует…". `--clean` strips the common ones and labels its output as not quotable.
- **Staged reading.** The order is list → summary + your private notes → a narrow transcript slice. For several meetings, the agent greps their summaries first instead of dumping six of them into context.
- **Honest answers.** Superwhisper summaries are model output and can invent decisions or give every task to one person. Every decision, task, owner and deadline in a recap carries evidence: a transcript timestamp, `(notes)`, or "(only in the summary, not verified)".
- **Gotchas built in.** JSON `datetime` is UTC while tables show local time. Speaker labels repeat or skip numbers. `meetings search` is FTS5 over summaries, transcripts and notes.
- **Safety.** Strictly read-only. Everything inside a recording is treated as data, never instructions. Nothing gets sent anywhere without an explicit "send it".

It's also lighter than MCP. There are no tool schemas in every prompt, and one folder serves every harness.

## Requirements

- macOS with the [Superwhisper](https://superwhisper.com) app, launched at least once
- the `superwhisper` CLI: `curl -fsSL https://superwhisper.com/install-cli.sh | bash` (details: [references/install.md](references/install.md))
- `jq` (preinstalled on recent macOS, otherwise `brew install jq`)

## Install

With the [`skills`](https://github.com/vercel-labs/skills) CLI:

```bash
npx skills add TheVilfer/superwhisper-skill
```

Or clone once and symlink into each agent, so `git pull` updates them all:

```bash
git clone https://github.com/TheVilfer/superwhisper-skill ~/.agents/skills/superwhisper
ln -sfn ~/.agents/skills/superwhisper ~/.claude/skills/superwhisper                       # Claude Code
ln -sfn ~/.agents/skills/superwhisper ~/.codex/skills/superwhisper                        # Codex
for d in ~/.aside/u/*/skills; do ln -sfn ~/.agents/skills/superwhisper "$d/superwhisper"; done  # Aside
```

Then ask your agent: *"What was my last meeting in Superwhisper about?"*

## What's inside

| Path | What |
| --- | --- |
| [`SKILL.md`](SKILL.md) | Rules, workflow and answer format for the agent |
| [`scripts/transcript.sh`](scripts/transcript.sh) | Compact transcript: speaker turns, `--from/--to`, `--split`, `--clean` |
| [`references/cli.md`](references/cli.md) | CLI v0.2.0 commands, flags and JSON fields, plus the MCP equivalent |
| [`references/workflows.md`](references/workflows.md) | Recap, period brief, standup from dictations, commitments, misrecognition diagnosis |
| [`references/install.md`](references/install.md) | Installing and updating the CLI, PATH, wiring and removal |
| [`tests/`](tests) | Fixture-based tests for `transcript.sh`, no Superwhisper needed |

### `transcript.sh`

```bash
scripts/transcript.sh a1b2c3d4                                   # whole meeting, ~90 s turns
scripts/transcript.sh a1b2c3d4 --clean --split 15 | grep -i -C1 pricing
scripts/transcript.sh a1b2c3d4 --from 12:40 --to 13:10           # exact quote: narrow window, no --clean
```

```
# Pricing sync  (2026-11-04 11:49:42.000 UTC, 18 min)
[00:01:05] Alice #0: Shall we start with pricing?
[00:01:09] Bob #1: Yes. We tested the new tier last week and ...
```

## Privacy

The CLI reads Superwhisper's local database and makes no network calls. Whatever transcript text the agent reads goes to *your agent's* model provider under its own data settings. The skill keeps that to the minimum the question needs.

## Development

```bash
tests/run.sh                                  # 15 fixture tests
shellcheck scripts/*.sh tests/run.sh
```

Issues and PRs are welcome, especially more hallucination patterns for other languages and new CLI versions.

## Credits

Recipes were adapted from the official `superwhisper-meetings` skill shipped inside the CLI, [vanducng/skills](https://github.com/vanducng/skills/tree/main/skills/superwhisper) and [SnowboardTechie/dotfiles](https://github.com/SnowboardTechie/dotfiles). The skill was reviewed with Codex and dogfooded on a real Aside agent.

## License

[MIT](LICENSE) © 2026 Sergei Polin
