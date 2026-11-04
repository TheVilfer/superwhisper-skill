<div align="center">

# superwhisper-skill

**Даёт ИИ-агенту читать твои встречи и диктовки из Superwhisper: локально, только на чтение и без лишней траты контекста.**

<a href="#установка">Установка</a> · <a href="SKILL.md">Скилл</a> · <a href="references/cli.md">Справка по CLI</a> · <a href="README.md">English</a>

</div>

Это [Agent Skill](https://agentskills.io) для Claude Code, Codex, Aside, Cursor, OpenCode, pi и любого агента, у которого есть shell. Со скиллом агент отвечает на вопросы вроде *«что решили по ценам на созвоне во вторник?»* по твоим записям [Superwhisper](https://superwhisper.com) через официальный локальный CLI `superwhisper`.

> Неофициальный проект сообщества, с Superwhisper / superultra inc. не связан.

## Зачем скилл, если есть MCP

У Superwhisper есть свой MCP-сервер (`superwhisper mcp`), и он работает. Скилл добавляет то, в чём агент без подсказки ошибается:

- **Экономия контекста.** Сырой транскрипт — JSON по одному слову, ~250 КБ на 20 минут. `scripts/transcript.sh` склеивает слова в реплики и уменьшает транскрипт примерно в 25 раз. Ещё он умеет вырезать отрезок по времени (`--from 12:00 --to 15:00`) и бить текст на короткие строки для grep (`--split 15`).
- **Галлюцинации Whisper.** На тишине Whisper сочиняет «Продолжение следует…», «Субтитры сделал DimaTorzok», «Thanks for watching!». `--clean` убирает самые частые и помечает такой вывод как непригодный для цитат.
- **Чтение по шагам.** Список → саммари и твои заметки → узкий кусок транскрипта. Если встреч несколько, агент сначала ищет нужное в их саммари, а не грузит шесть саммари целиком.
- **Честные ответы.** Саммари Superwhisper пишет модель: она может придумать решения или повесить все задачи на одного человека. У каждого решения, задачи, ответственного и срока есть пометка, откуда он взят: таймкод, `(заметки)` или «(только в саммари, не проверено)».
- **Известные подвохи.** В JSON `datetime` в UTC, а в таблицах местное время. Номера спикеров повторяются и пропускаются. `meetings search` — это полнотекстовый поиск (FTS5) по саммари, транскриптам и заметкам.
- **Безопасность.** Только чтение. Всё, что есть в записи, считается данными, а не инструкциями. Отправить что-либо агент может только после явного «отправляй».

Ещё скилл легче MCP: схемы инструментов не попадают в каждый запрос, а одна папка обслуживает все харнессы.

## Требования

- macOS и приложение [Superwhisper](https://superwhisper.com), запущенное хотя бы раз
- CLI `superwhisper`: `curl -fsSL https://superwhisper.com/install-cli.sh | bash` (подробности в [references/install.md](references/install.md))
- `jq` (в свежих macOS уже есть, иначе `brew install jq`)

## Установка

Через CLI [`skills`](https://github.com/vercel-labs/skills):

```bash
npx skills add TheVilfer/superwhisper-skill
```

Или склонируй один раз и подключи симлинками к каждому агенту, тогда один `git pull` обновит всех:

```bash
git clone https://github.com/TheVilfer/superwhisper-skill ~/.agents/skills/superwhisper
ln -sfn ~/.agents/skills/superwhisper ~/.claude/skills/superwhisper                       # Claude Code
ln -sfn ~/.agents/skills/superwhisper ~/.codex/skills/superwhisper                        # Codex
for d in ~/.aside/u/*/skills; do ln -sfn ~/.agents/skills/superwhisper "$d/superwhisper"; done  # Aside
```

Проверка: спроси агента *«О чём была моя последняя встреча в Superwhisper?»*

## Что внутри

| Путь | Что |
| --- | --- |
| [`SKILL.md`](SKILL.md) | Правила, порядок работы и формат ответа для агента |
| [`scripts/transcript.sh`](scripts/transcript.sh) | Компактный транскрипт: реплики, `--from/--to`, `--split`, `--clean` |
| [`references/cli.md`](references/cli.md) | Команды, флаги и поля JSON CLI v0.2.0, аналог через MCP |
| [`references/workflows.md`](references/workflows.md) | Итог встречи, бриф за период, стендап по диктовкам, обещания, ошибки распознавания |
| [`references/install.md`](references/install.md) | Установка и обновление CLI, PATH, подключение и удаление |
| [`tests/`](tests) | Тесты `transcript.sh` на фикстурах, Superwhisper для них не нужен |

## Приватность

CLI читает локальную базу Superwhisper и в сеть не ходит. Текст транскрипта, который прочитал агент, уходит провайдеру модели *твоего агента* по его правилам обработки данных. Скилл ограничивает это тем, что нужно для ответа на вопрос.

## Разработка

```bash
tests/run.sh                                  # 15 тестов на фикстурах
shellcheck scripts/*.sh tests/run.sh
```

Issues и PR приветствуются, особенно шаблоны галлюцинаций для других языков и поддержка новых версий CLI.

## Благодарности

Рецепты взяты из официального скилла `superwhisper-meetings`, который поставляется внутри CLI, а также из [vanducng/skills](https://github.com/vanducng/skills/tree/main/skills/superwhisper) и [SnowboardTechie/dotfiles](https://github.com/SnowboardTechie/dotfiles). Скилл прошёл ревью в Codex и проверку на живом агенте Aside.

## Лицензия

[MIT](LICENSE) © 2026 Sergei Polin
