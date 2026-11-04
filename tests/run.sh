#!/usr/bin/env bash
# Tests for scripts/transcript.sh against fixtures (no Superwhisper needed).
set -uo pipefail
cd "$(dirname "$0")/.." || exit 1
export SUPERWHISPER_BIN="$PWD/tests/fixtures/fake-superwhisper"
T=scripts/transcript.sh
fail=0

check() { # name, expected substring (or !substring for absence), command...
  local name="$1" want="$2" out pass=false; shift 2
  out="$("$@" 2>&1)"
  if [[ "$want" == !* ]]; then
    [[ "$out" != *"${want#!}"* ]] && pass=true
  else
    [[ "$out" == *"$want"* ]] && pass=true
  fi
  if $pass; then echo "ok   $name"; else echo "FAIL $name"; printf '     %s\n' "$out"; fail=1; fi
}

export FIXTURE=tests/fixtures/meeting.json
check "header in UTC"              "# Pricing sync  (2026-11-04 11:49:42.000 UTC, 5 min)" $T
check "merges word segments"       "[00:00:05] Alice #0: Let's talk pricing." $T
check "keeps filler by default"    "Продолжение следует..." $T
check "--clean drops null filler"  "!Продолжение" $T --clean
check "--clean marks output"       "[--clean: filler removed, not for quotes]" $T --clean
check "--clean strips phrase"      "Bob #1: Price goes up. Спасибо." $T --clean
check "named Спасибо kept"         "Спасибо." $T --clean
check "split on 90 s gap"          "[00:02:00] Bob #1: New turn after the gap." $T
check "unknown speaker number"     "Speaker 7 #7: Unknown number." $T
check "--from/--to window"         "!Let's" $T --from 1:00 --to 2:10
check "--from/--to keeps inside"   "New turn after the gap." $T --from 1:00 --to 2:10
check "--split splits a turn"     "[00:00:05] Alice #0: talk pricing." $T --split 0.4
check "rejects bad --split"        "must be numbers" $T --split abc
check "rejects unknown option"     "unknown option" $T --bogus

printf '{"title":"Empty","datetime":"x"}' > "${TMPDIR:-/tmp}/sw-empty.json"
FIXTURE="${TMPDIR:-/tmp}/sw-empty.json" check "no segments message" "(no transcript segments" $T

exit $fail
