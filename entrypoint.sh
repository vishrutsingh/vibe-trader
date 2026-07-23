#!/usr/bin/env bash
set -e
if [ -f /trader/.env ]; then
  set -a; source /trader/.env; set +a
fi
exec "$@"