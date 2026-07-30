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
  # "unavailable" means no IOAccelerator published "Device Utilization %" at
  # all. Checked separately from the range test because it is the failure the
  # app cannot show you: absent statistics and a fully idle GPU both render as
  # a flat graph. Note the converse is NOT an error — a real 0 is legitimate on
  # an idle machine, so this gate deliberately does not fail on zero samples.
  if [[ "$v" == "unavailable" ]]; then
    echo "FAIL: no accelerator published 'Device Utilization %' — the sampler"
    echo "      found nothing to read. See docs/ARCHITECTURE.md (GPU key)."
    exit 1
  fi
  if ! [[ "$v" =~ ^[0-9]+$ ]] || (( v > 100 )); then
    echo "FAIL: sample '$v' is not an integer in 0-100"
    exit 1
  fi
done <<< "$out"

echo "OK: sampler returns plausible values"
