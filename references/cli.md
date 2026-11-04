# superwhisper CLI: reference (v0.2.0)

Common flags: `--json` (machine-readable), `--db <PATH>` / `SUPERWHISPER_DB`, `--settings <PATH>` / `SUPERWHISPER_SETTINGS`.
Dates in `--since` / `--before`: `YYYY-MM-DD` or ISO8601. In table/text output time is local; in JSON it is **UTC**.

## Meetings

| Command | Flags | What it does |
| --- | --- | --- |
| `meetings` | `-l` (20), `-o`, `--since`, `--before`, `--json` | List of meetings, newest first |
| `meetings search <FTS5>` | same | Meetings only, newest first. Indexes titles, summaries, transcripts, `privateNotes` and people fields |
| `meetings read [ID]` | `--transcript`, `--json` | One meeting; ID = UUID or a unique hex prefix; no ID → latest |

`meetings --json` → `[{id, datetime, durationMs, title, attendees[], indexedSpeakerNames[]}]`

`meetings read --json` → `{id, title, datetime, durationMs, attendees[], speakers[{name, number}], indexedSpeakerNames[], summary, privateNotes}`
- `summary` — markdown: an intro paragraph plus `##` sections with bullets (decisions, action items).
- `privateNotes` — the user's own notes (a string, often empty); the strongest evidence.
- `speakers[{number, name, suggestedName?}]` — numbers can skip values and one name can sit under several numbers; `suggestedName` is a guess, not a confirmed identity.
- `--before` is exclusive, `--since` is inclusive.

`--transcript` adds `segments[{start, end, speaker, text, words[]}]`:
- one segment ≈ one word or short phrase (3000+ for 45 minutes);
- `speaker` = `number` from `speakers`, or `null` (silence/noise, usually hallucinations);
- `start`/`end` are seconds from the start of the recording.
In text form, `--transcript` prints `[mm:ss] Name: word` line by line. Prefer `scripts/transcript.sh`.

## Dictations and all recordings

| Command | Flags | What it does |
| --- | --- | --- |
| `search <FTS5>` | `-l` (20), `--since`, `--before`, `--sort relevance\|date`, `--json` | Full text across all recordings, meetings included. No `--mode` |
| `history` | `-l` (10), `-o`, `-m <Mode>`, `--since`, `--before`, `--json` | Latest recordings |
| `read [ID]` | `--raw`, `--json` | One recording; no ID → latest |
| `export` | `-f jsonl\|markdown`, `-m`, `--since`, `--before`, `-o <file>` | Everything, oldest first. Large output, always cap it with a date window and `-o` |
| `stats` | `--json` | `{recordingCount, totalWordsTranscribed, totalDurationMs, averageWordsPerMinute, totalAppsUsed}` |
| `modes` | | Modes and recording counts (`Super`, `Meeting`, `Default`, …) |

`read --json` → `{id, datetime, createdAt, duration (ms), modeName, rawResult, llmResult, rawWordCount, llmWordCount, modelName, languageModelName, prompt, promptContext, folderName, fromFile, recordingDevice, appVersion}`
- `rawResult` — what was recognised; `llmResult` — after the mode's AI processing (what got inserted into the app).

## FTS5

`word` · `"exact phrase"` · `a AND b` · `a OR b` · `a NOT b` · `prefix*`. Russian inflects, so search by stem: `регистрац*`, `франц*`.

## Not for an agent without an explicit request

`vocab add|remove`, `snippets set|remove`, `record`, `start`, `stop`, `switch`, `settings`, `transcribe <file>` (needs Pro), `mcp install|uninstall`. These change the app's state or settings.
`doctor` is safe: database diagnostics for bug reports.

## Where the data lives (for diagnostics only; read through the CLI)

- Database: `~/Library/Application Support/superwhisper/database/superwhisper.sqlite` (`superwhisper doctor` shows the path, the number of recordings and the latest one).
- Recordings: `~/Documents/superwhisper/recordings/<unix-epoch>/meta.json` + audio. The app indexes folders into SQLite when it starts.

## MCP equivalent

`superwhisper mcp` (stdio) → tools `meetings`, `search_meetings`, `read_meeting(id?, transcript)`, `search`, `history`, `read_recording`, `stats`, `modes`, `vocab_*`, `snippets_*`.
If a harness already has these tools connected, you can use them instead of shell commands. Don't register MCP yourself.

## Sources

- Official CLI documentation: https://superwhisper.com/docs/get-started/cli (repo superultrainc/superwhisper-docs, `get-started/cli.mdx`)
- Meetings and agents: https://superwhisper.com/docs/meetings/share
- Official `superwhisper-meetings` skill and MCP server instructions: embedded in the CLI binary (`superwhisper mcp install claude-code` installs it)
- Binaries: https://github.com/superultrainc/superwhisper-cli-release
- Community skills: https://github.com/vanducng/skills/tree/main/skills/superwhisper, https://github.com/SnowboardTechie/dotfiles (dot-agents/skills/superwhisper-meetings, hermes/automations/workday-morning-brief)
- Voice replies in coding agents (a separate thing): superultrainc/superwhisper-claude-code, superwhisper-codex, superwhisper-grok, opencode-superwhisper, pi-superwhisper
