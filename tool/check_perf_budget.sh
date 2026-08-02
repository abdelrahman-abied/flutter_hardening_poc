#!/usr/bin/env bash
# Article 6, Gate 2 — fail the build if the 90th-percentile raster time
# regresses past the 16 ms (60 Hz) frame budget.
#
# Reads the report written by test_driver/perf_driver.dart.
set -euo pipefail

REPORT="build/integration_response_data.json"
BUDGET_MS="${RASTER_BUDGET_MS:-16.0}"

if [[ ! -f "$REPORT" ]]; then
  echo "❌ $REPORT not found — did the perf drive run?"
  exit 1
fi

P90=$(jq -r '.home_scroll."90th_percentile_frame_rasterizer_time_millis"' "$REPORT")

if [[ "$P90" == "null" || -z "$P90" ]]; then
  echo "❌ raster p90 missing from report"
  exit 1
fi

echo "raster p90 = ${P90} ms (budget ${BUDGET_MS} ms)"
awk -v v="$P90" -v b="$BUDGET_MS" 'BEGIN { exit !(v < b) }' \
  || { echo "❌ raster p90 ${P90} ms exceeds ${BUDGET_MS} ms budget"; exit 1; }
echo "✅ within budget"
