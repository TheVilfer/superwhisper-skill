#!/usr/bin/env bash
# Compact Superwhisper meeting transcript: merges word-level segments into speaker turns.
# Usage: transcript.sh [MEETING_ID|prefix] [--from T] [--to T] [--split S] [--clean]
#   No ID → latest meeting. T = seconds, mm:ss or hh:mm:ss (segments overlapping the window).
#   Output: "[hh:mm:ss] Speaker #N: text", one line per turn, turns split every S s (default 90).
#   For grep use --split 15: short lines, so a match does not drag in 90 s of text.
#   --clean  drop typical Whisper hallucinations (speaker-less "Продолжение"/"следует..."/"Спасибо.",
#            "Субтитры сделал DimaTorzok", "Продолжение следует...", "Thanks for watching!",
#            "Subtitles by the Amara.org community"). May remove real speech:
#            never use --clean output for exact quotes.
set -euo pipefail

SW="${SUPERWHISPER_BIN:-$(command -v superwhisper 2>/dev/null || echo "$HOME/.local/bin/superwhisper")}"
JQ="$(command -v jq 2>/dev/null || echo /usr/bin/jq)"

to_sec() { # seconds | mm:ss | hh:mm:ss → seconds
  echo "$1" | awk -F: '{ if (NF==1) print $1; else if (NF==2) print $1*60+$2; else print $1*3600+$2*60+$3 }'
}

id=""; clean=false; from=0; to=1000000000; split=90
while [ $# -gt 0 ]; do
  case "$1" in
    --clean) clean=true ;;
    --from) from="$(to_sec "$2")"; shift ;;
    --to) to="$(to_sec "$2")"; shift ;;
    --split) split="$2"; shift ;;
    -h|--help) sed -n '2,10p' "$0"; exit 0 ;;
    -*) echo "unknown option: $1" >&2; exit 2 ;;
    *) id="$1" ;;
  esac
  shift
done

case "$split$from$to" in *[!0-9.]*) echo "--from/--to/--split must be numbers or mm:ss / hh:mm:ss" >&2; exit 2 ;; esac

# shellcheck disable=SC2016  # $vars below are jq variables, not shell ones
"$SW" meetings read ${id:+"$id"} --json --transcript | "$JQ" -r \
  --argjson clean "$clean" --argjson from "$from" --argjson to "$to" --argjson split "$split" '
  (.speakers // []) as $sp
  | def pad: tostring | if length < 2 then "0" + . else . end;
    def ts($s): ($s | floor) as $t | "\($t/3600|floor|pad):\($t%3600/60|floor|pad):\($t%60|pad)";
    def name($n): if $n == null then "?" else ((($sp | map(select(.number == $n)) | .[0].name) // "Speaker \($n)") + " #\($n)") end;
    def filler: test("^\\s*(Продолжение|[Сс]ледует\\.*|Спасибо\\.?|Субтитры.*|Thank you\\.?|Thanks for watching!?|\\.+)\\s*$"; "i");
  "# \(.title // "untitled")  (\(.datetime) UTC, \((.durationMs // 0)/60000|floor) min)\(if $clean then "  [--clean: filler removed, not for quotes]" else "" end)",
  ( (.segments // []) as $segs
    | if ($segs | length) == 0 then "(no transcript segments for this meeting)"
      else
        [ $segs[]
          | select((.end // .start) >= $from and .start <= $to)
          | select(($clean | not) or (.speaker != null) or ((.text | filler) | not)) ]
        | reduce .[] as $s ([];
            if length > 0 and .[-1].speaker == $s.speaker and ($s.start - .[-1].start) < $split
            then .[-1].text += " " + ($s.text | ltrimstr(" "))
            else . + [{speaker: $s.speaker, start: $s.start, text: ($s.text | ltrimstr(" "))}] end)
        | .[]
        | .text |= (if $clean then gsub("(Субтитры (сделал|создавал) DimaTorzok|[Сс]делал DimaTorzok|[Сс]оздавал DimaTorzok|[Пп]родолжение следует\\.\\.\\.|Subtitles by the Amara\\.org community|Thanks for watching!)\\s*"; "") else . end)
        | select(.text | test("\\S"))
        | "[\(ts(.start))] \(name(.speaker)): \(.text)"
      end )'
