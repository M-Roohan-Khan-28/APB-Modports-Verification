#!/usr/bin/env bash
set -euo pipefail
export LC_ALL=C
cd "$(dirname "$0")/.."
output="${1:-${TMPDIR:-/tmp}/apb-modports-regression-$(date +%Y%m%d%H%M%S)-$$}"
python3 scripts/run_contract.py --output-dir "$output"
