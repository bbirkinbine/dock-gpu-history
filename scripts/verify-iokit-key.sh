#!/bin/bash
# Confirms the IORegistry key this app reads exists on this machine.
# If nothing prints, the sampler needs a different key -- see HANDOFF.md task 2.
echo "Looking for utilization keys in IOAccelerator PerformanceStatistics..."
ioreg -r -c IOAccelerator -w0 | grep -iE 'utilization|activity' || echo "NOT FOUND - sampler key needs adjustment"
