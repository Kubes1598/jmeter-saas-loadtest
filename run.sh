#!/usr/bin/env bash
# Headless JMeter run with HTML reporter.
# Usage: ./run.sh [host] [users] [p95_budget_ms]
set -euo pipefail

HOST="${1:-staging.example.com}"
USERS="${2:-500}"
P95="${3:-800}"

mkdir -p results
rm -f results/run.jtl

jmeter -n \
  -t saas-loadtest.jmx \
  -l results/run.jtl \
  -e -o "results/html-$(date +%s)" \
  -Jhost="$HOST" \
  -Jusers="$USERS" \
  -Jp95_budget="$P95"

echo "Done. Open results/html-*/index.html in a browser."
