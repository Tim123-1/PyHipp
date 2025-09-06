#!/usr/bin/env bash
set -euo pipefail

JOB_DIR="${1:-.}"

# Prefer queue-style names; fall back to ip-style
resolve_outs_for_array_ids() {
  local dir="$1"; shift
  local -a ids=( "$@" )
  local -a found=()
  shopt -s nullglob

  for id in "${ids[@]}"; do
    local got=0

    # 1) Prefer queue-style (what you want to display)
    for f in "$dir"/*queue*."$id".out "$dir"/*queue*-"$id".out; do
      [[ -e "$f" ]] || continue
      found+=( "$f" )
      got=1
    done

    # 2) Fall back to anything ending with .<id>.out or -<id>.out
    if [[ $got -eq 0 ]]; then
      for f in "$dir"/*."$id".out "$dir"/*-"$id".out; do
        [[ -e "$f" ]] || continue
        found+=( "$f" )
        got=1
      done
    fi

    if [[ $got -eq 0 ]]; then
      echo "Warning: no output file for array index $id in $dir" >&2
    fi
  done

  printf "%s\n" "${found[@]}" | sort -u
}


echo
echo "Number of hkl files"
find "$JOB_DIR" -type f -name '*.hkl' | grep -v -e spiketrain -e mountains | wc -l
echo "Number of mda files"
find "$JOB_DIR" -type f -name "firings.mda" | wc -l
echo

echo "#==========================================================="
echo "Start Times"

mapfile -t OUTS < <(find "$JOB_DIR" -maxdepth 1 -type f -name '*.out' | sort)

if (( ${#OUTS[@]} == 0 )); then
  echo "(no .out files found in $JOB_DIR)" >&2
  exit 0
fi

for f in "${OUTS[@]}"; do
  echo "==> $(basename "$f") <=="
  # First occurrence of time.struct_time
  if ! grep -m1 -E 'time\.struct_time' "$f"; then
    echo "(no start time found)"
  fi
  echo
done

echo "End Times"
# For each .out, print from the LAST time.struct_time to the end of file
for f in "${OUTS[@]}"; do
  echo "==> $(basename "$f") <=="
  awk '
    /time\.struct_time/ { last=NR }
    { buf[NR]=$0 }
    END {
      if (last > 0) {
        for (i=last; i<=NR; i++) print buf[i]
      } else {
        print "(no end time found)"
      }
    }
  ' "$f"
  echo
done

echo "#==========================================================="

