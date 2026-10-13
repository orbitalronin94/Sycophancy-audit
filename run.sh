#!/usr/bin/env bash
set -euo pipefail

# Carga variables de entorno
[ -f .env ] && export $(grep -v '^#' .env | xargs)

case "${1:-serve}" in
  serve)
    exec python sycophancy_api.py serve --host "${AUDIT_HOST:-0.0.0.0}" --port "${AUDIT_PORT:-8000}" "${@:2}"
    ;;
  run)
    shift
    exec python sycophancy_api.py run "$@"
    ;;
  install)
    pip install -r requirements.txt
    ;;
  *)
    echo "Uso: ./run.sh {install|serve|run [args]}"
    exit 1
    ;;
esac
