#!/bin/sh
set -euo pipefail
cd "$(dirname "$0")/.."
exec make run
