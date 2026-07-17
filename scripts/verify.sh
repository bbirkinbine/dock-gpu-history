#!/bin/bash
# Machine-checkable verify gate: build, then confirm the sampler returns
# plausible values via the headless --sample mode. The visual half of the
# check (dock graph moves under load, no flicker) still needs a human.
set -euo pipefail
cd "$(dirname "$0")/.."

./scripts/build.sh

out=$(./build/gpudockhistory --sample 3)
echo "samples: $(echo "$out" | tr '\n' ' ')"

while read -r v; do
  if ! [[ "$v" =~ ^[0-9]+$ ]] || (( v > 100 )); then
    echo "FAIL: sample '$v' is not an integer in 0-100"
    exit 1
  fi
done <<< "$out"

echo "OK: sampler returns plausible values"
