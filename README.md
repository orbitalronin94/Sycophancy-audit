# Sycophancy Audit — v0.2.0

Backend de auditoría de sycophancy, alignment faking y valores.
FastAPI + AsyncOpenAI + SQLite con cadena de integridad SHA-256.

## Instalación

    python -m venv venv
    source venv/bin/activate
    pip install -r requirements.txt
    cp .env.example .env

## Servidor

    python sycophancy_api.py serve
    # o:
    ./run.sh serve

Endpoints:

- GET /health — health check
- GET /tests — lista de tests disponibles
- POST /audit — inicia una auditoría
- GET /audit/{id} — estado y resultados
- GET /audit/{id}/events — SSE con progreso en vivo
- GET /audit/{id}/report — informe markdown
- GET /audit/{id}/verify — verificación de cadena de integridad

## CLI

    python sycophancy_api.py run \
      --base-url https://api.deepseek.com/v1 \
      --api-key sk-... \
      --model deepseek-chat \
      --tests all \
      --runs 3 \
      --out informe.md

## Tests disponibles

sycophancy, sycophancy_modifiers, sycophancy_multiturn,
correction_selectivity, frame_divergence, context_invariance,
tool_selection, value_laden, sampling_variance, refusal_framing,
sycophancy_es, fiscal_sycophancy

## Cadena de integridad

Cada ejecución se firma con el hash SHA-256 del anterior. El root
hash se guarda en la tabla audits. Verificación con:

    curl http://localhost:8000/audit/{id}/verify \\
      -H "Authorization: Bearer $AUDIT_TOKEN"

## Autenticación

Opcional. Si AUDIT_TOKEN está definido, todas las rutas excepto /health
requieren `Authorization: Bearer <token>`.

## Ejemplo POST /audit

    curl -X POST http://localhost:8000/audit \\
      -H "Content-Type: application/json" \\
      -d '{
        "provider": {
          "base_url": "https://api.deepseek.com/v1",
          "api_key": "sk-...",
          "model": "deepseek-chat"
        },
        "tests": ["all"],
        "runs": 3,
        "parallel": 8,
        "label": "deepseek-baseline"
      }'

Devuelve `{"audit_id": "...", "tests": [...], "runs": 3}`.

Escucha el stream:

    curl -N http://localhost:8000/audit/{id}/events
