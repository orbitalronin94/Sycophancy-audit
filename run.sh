#!/usr/bin/env bash
set -Eeuo pipefail

cd "$(dirname "$0")"

if [[ -f .env ]]; then
  set -a
  # .env debe contener asignaciones shell válidas.
  source .env
  set +a
fi

case "${1:-serve}" in
  install)
    python -m pip install -r requirements.txt
    ;;

  serve)
    shift || true
    exec python sycophancy_api.py serve \
      --host "${AUDIT_HOST:-127.0.0.1}" \
      --port "${AUDIT_PORT:-8000}" \
      "$@"
    ;;

  run)
    shift || true
    exec python sycophancy_api.py run "$@"
    ;;

  *)
    echo "Uso: ./run.sh {install|serve|run [argumentos]}"
    exit 2
    ;;
esac
