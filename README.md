# Sycophancy Audit

**An experimental framework for auditing sycophancy, response consistency, and resistance to user pressure in large language models (LLMs).**

Sycophancy Audit evaluates whether an LLM changes its answers to agree with a user's stated beliefs, responds differently to leading questions, or maintains consistent answers under social pressure.

The project provides a Python API built with FastAPI, configurable OpenAI-compatible providers, asynchronous test execution, SQLite persistence, hash-chain integrity checks, and server-sent events (SSE) for monitoring audit progress.

> **Research tool, not a certification system.** Results depend on the model, prompts, provider, and evaluation heuristics. Scores should be interpreted as experimental indicators, not definitive measurements of model behavior.

## Table of contents

- [Features](#features)
- [How it works](#how-it-works)
- [Requirements](#requirements)
- [Installation](#installation)
- [Configuration](#configuration)
- [Running the application](#running-the-application)
- [Running an audit](#running-an-audit)
- [API overview](#api-overview)
- [Results and persistence](#results-and-persistence)
- [Security considerations](#security-considerations)
- [Limitations](#limitations)
- [Development and testing](#development-and-testing)
- [Project structure](#project-structure)
- [Contributing](#contributing)
- [License](#license)

## Features

- **Configurable LLM providers:** Supply an API-compatible base URL, model name, and API key.
- **Behavioral test scenarios:** Probe answer changes under leading questions, user pressure, and other conversational conditions.
- **Asynchronous execution:** Run independent prompts concurrently, subject to configured concurrency limits.
- **SQLite persistence:** Store audit metadata, individual runs, and evaluation results locally.
- **Hash-chain integrity checks:** Detect certain forms of accidental or unauthorized modification to stored audit records.
- **Progress events:** Stream audit progress using server-sent events.
- **API authentication:** Optionally protect endpoints with a bearer token.
- **Configurable execution:** Set concurrency, timeout, retry, database, and CORS settings through environment variables.

## How it works

An audit selects one or more test scenarios, sends prompts to the configured LLM provider, stores the responses, and applies the corresponding analysis logic.

A typical workflow is:

1. Configure a provider and model.
2. Submit an audit request.
3. Execute the selected tests and collect responses.
4. Analyze the responses using test-specific rules.
5. Persist the results and monitor progress.
6. Review the output while accounting for test limitations and failed requests.

### Test scenarios

The codebase includes test classes covering several types of behavior, including:

- **Baseline sycophancy:** Checks whether an answer changes after the user expresses a conflicting belief.
- **Prompt modifiers:** Examines how leading statements, flattery, or appeals to authority may affect responses.
- **Multi-turn behavior:** Evaluates responses across a sequence of conversational turns.
- **Additional specialized scenarios:** Includes other test classes defined in `sycophancy_api.py`.

The exact tests available depend on the version of the code. Consult the test registry in `sycophancy_api.py` before relying on a particular test name or identifier.

### Conversational versus independent prompts

Independent prompts can be executed concurrently because each request is evaluated separately.

Conversational tests require special care: a genuine multi-turn evaluation must send previous user messages and assistant responses as conversation history. Sending every prompt as a separate, stateless request does not measure the same behavior.

Before interpreting multi-turn results, verify that the current implementation preserves the message history and correctly handles failed turns.

## Requirements

- Python 3.11 or newer is recommended if the implementation uses `asyncio.timeout`.
- An API key for the LLM provider you intend to use.
- Network access to that provider, unless using a local, compatible endpoint.

The application dependencies are listed in `requirements.txt`.

## Installation

Clone the repository:

```bash
git clone https://github.com/orbitalronin94/Sycophancy-audit.git
cd Sycophancy-audit
```

Create and activate a virtual environment:

```bash
python -m venv .venv
```

Linux/macOS:

```bash
source .venv/bin/activate
```

Windows PowerShell:

```powershell
.venv\Scripts\Activate.ps1
```

Install the dependencies:

```bash
python -m pip install --upgrade pip
python -m pip install -r requirements.txt
```

If the repository contains a `run.sh` script with an `install` command, you can alternatively use:

```bash
chmod +x run.sh
./run.sh install
```

## Configuration

Create a local `.env` file in the project root. Do not commit this file or share its secrets.

Example configuration:

```dotenv
# Server
AUDIT_HOST=127.0.0.1
AUDIT_PORT=8000

# API authentication
AUDIT_TOKEN=replace-with-a-long-random-secret

# Database
AUDIT_DB=./audit.db

# CORS: comma-separated allowed origins
AUDIT_CORS_ORIGINS=http://localhost:3000,http://127.0.0.1:3000

# Execution
AUDIT_MAX_PARALLEL=4
AUDIT_TIMEOUT=60
AUDIT_MAX_RETRIES=3
```

These are example values. Confirm that each variable is read by the current application version before relying on it.

### Configuration reference

| Variable | Purpose |
|---|---|
| `AUDIT_HOST` | Interface on which the server listens. |
| `AUDIT_PORT` | Server port. |
| `AUDIT_TOKEN` | Bearer token used to authenticate protected API requests. |
| `AUDIT_DB` | SQLite database path, if supported by the current configuration. |
| `AUDIT_CORS_ORIGINS` | Comma-separated list of permitted browser origins. |
| `AUDIT_MAX_PARALLEL` | Default concurrency limit. |
| `AUDIT_TIMEOUT` | LLM request timeout in seconds. |
| `AUDIT_MAX_RETRIES` | Maximum retry setting for failed requests. |

The exact environment variable names and defaults are defined in `sycophancy_api.py`. If the code uses a different database variable name, use the name actually implemented there.

### Provider configuration

Provider credentials are supplied as part of the audit request rather than stored in the repository.

A provider configuration typically contains:

- `base_url`: the provider's API endpoint.
- `api_key`: the provider's secret API key.
- `model`: the model identifier accepted by that endpoint.

Use HTTPS for remote providers. Only use HTTP for local endpoints when the implementation explicitly permits it.

Do not expose API keys in URLs, source code, logs, screenshots, or version control.

## Running the application

Start the server using the helper script:

```bash
./run.sh serve
```

Or start it directly if the application supports the `serve` subcommand:

```bash
python sycophancy_api.py serve --host 127.0.0.1 --port 8000
```

The default local address is typically:

```text
http://127.0.0.1:8000
```

If FastAPI's OpenAPI documentation is enabled, interactive API documentation is generally available at:

```text
http://127.0.0.1:8000/docs
```

For local development, bind to `127.0.0.1`. Binding to `0.0.0.0` makes the service listen on all available network interfaces and should only be done when the deployment is appropriately secured.

To inspect the available command-line options:

```bash
python sycophancy_api.py --help
```

## Running an audit

The application exposes an HTTP API for starting audits. The precise request schema and endpoint behavior are defined by the Pydantic models and route handlers in `sycophancy_api.py`.

An audit request uses a structure similar to the following:

```json
{
  "provider": {
    "base_url": "https://api.example.com/v1",
    "api_key": "YOUR_API_KEY",
    "model": "YOUR_MODEL_NAME"
  },
  "tests": ["all"],
  "runs": 3,
  "parallel": 4,
  "label": "baseline-evaluation"
}
```

This is an illustrative request body, not a guarantee that every provider or model supports the supplied values. Replace the endpoint, key, and model with valid values for your provider.

The current request model defines:

- `provider`: the LLM connection configuration.
- `tests`: the selected tests; the default is `["all"]`.
- `runs`: the number of runs, constrained to 1–20 by the request model.
- `parallel`: the requested concurrency, constrained to 1–32 by the request model.
- `label`: an optional label for the audit.

### Authentication

If `AUDIT_TOKEN` is configured, protected endpoints expect a bearer token:

```http
Authorization: Bearer YOUR_AUDIT_TOKEN
```

If authentication is enabled, send the token with the request. Do not put it in a query parameter.

The current application returns a service-unavailable error when authentication is required by the implementation but `AUDIT_TOKEN` is not configured. Configure the token before exposing the API to other users or networks.

### Example request

The following is a template. Replace `/audit` with the actual audit-start route if the route name changes in your version.

```bash
curl -X POST "http://127.0.0.1:8000/audit" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_AUDIT_TOKEN" \
  -d '{
    "provider": {
      "base_url": "https://api.example.com/v1",
      "api_key": "YOUR_API_KEY",
      "model": "YOUR_MODEL_NAME"
    },
    "tests": ["all"],
    "runs": 3,
    "parallel": 4,
    "label": "baseline-evaluation"
  }'
```

Check the route implementation and response model for the actual response structure, audit identifier, and status codes.

## API overview

The API is implemented in `sycophancy_api.py` using FastAPI.

The code includes functionality for starting audits, tracking their execution, storing results, and checking the integrity of the audit record chain.

| Capability | Description |
|---|---|
| Start audit | Accepts an audit configuration and initiates execution. |
| Audit status and results | Exposes audit information as implemented by the registered routes. |
| Progress streaming | Uses SSE to communicate progress events. |
| Integrity verification | Checks stored records against their hash-chain values. |

For the authoritative endpoint list, request parameters, response bodies, and status codes, inspect the FastAPI route definitions or the generated OpenAPI schema at `/openapi.json` when enabled.

### Server-sent events (SSE)

The application uses SSE for progress updates. An SSE client connects to the corresponding event-stream endpoint and listens for events while an audit runs.

The precise URL and event names must match the route implementation. If multiple clients need to monitor the same audit, verify that each subscriber receives the complete event stream independently; a shared queue can cause events to be distributed between subscribers instead of broadcast to all of them.

## Results and persistence

Audit records are stored in SQLite when database persistence is enabled. Stored information can include audit metadata, prompts, model responses, execution timing, and analysis results.

Treat the database as potentially sensitive: prompts and responses may contain confidential data.

### Hash-chain integrity

The application implements hash-chain verification for stored records. This can help identify modifications that invalidate the expected chain.

A hash chain is **not equivalent to a digital signature or tamper-proof storage**. Someone with sufficient control over the database and the implementation can potentially rewrite records and recompute hashes. For stronger evidence preservation, consider signed checkpoints, external append-only storage, restricted database access, and independently stored verification records.

### Interpreting metrics

The current analyzers use test-specific rules and heuristics. Depending on the test, these may include keyword checks, answer comparisons, text similarity, or other simple indicators.

These metrics should be treated as proxies for behavior rather than universal measurements of sycophancy.

### Benchmark provenance

Some scenarios are inspired by published research or benchmark concepts, but this repository does **not** claim to reproduce those benchmarks. The included prompts, response classifiers, sample sizes, and scoring rules are project-specific; official benchmark datasets and scoring implementations are not bundled here. Source labels in reports indicate inspiration or intended context, not official benchmark certification, and scores must not be compared directly with published benchmark results. For a reproducible research comparison, use the original benchmark protocol and its official evaluation code.

For meaningful comparisons:

1. Keep the model identifier and provider settings fixed.
2. Record the test version and configuration.
3. Use the same prompt set and comparable execution conditions.
4. Repeat tests to assess variability.
5. Inspect individual responses alongside aggregate scores.
6. Report failed requests separately from valid model responses.

An API failure must not be interpreted as a model answer. Tests with failed or missing responses should be marked as failed or unevaluable rather than assigned a misleading score.

## Security considerations

Before deploying this service beyond a trusted local environment, review the following controls.

### Protect credentials

- Keep `.env` out of version control.
- Never include provider keys in logs or audit reports.
- Avoid returning secret configuration fields in API responses.
- Rotate credentials that may have been exposed.

### Restrict network access

The API accepts a provider URL. If users can submit arbitrary URLs, a publicly reachable deployment may be vulnerable to server-side request forgery (SSRF).

The application rejects literal non-public IP addresses and common local/internal hostnames by default, and only permits plain HTTP for localhost. This is a useful guardrail, not a complete SSRF defense: DNS rebinding and public-looking hostnames that resolve to private addresses still require an outbound firewall or a provider allowlist.

For a trusted deployment that intentionally uses a private HTTPS provider, set `AUDIT_ALLOW_PRIVATE_PROVIDER_HOSTS=1`. This disables the local/private destination checks and must not be enabled when untrusted users can submit provider URLs.

### Configure CORS carefully

Avoid wildcard CORS origins in production unless they are specifically required and appropriate for the deployment. Allow only the browser origins that need access.

CORS is not authentication and does not protect an API from direct requests.

### Authenticate requests

Set a strong `AUDIT_TOKEN` and keep the service on a private network unless public access is an explicit requirement. For multi-user deployments, consider a proper identity and authorization layer, rate limiting, and audit logging.

### Protect stored data

- Restrict permissions on the SQLite database and its directory.
- Exclude local database files from Git.
- Establish a retention policy for prompts and responses.
- Encrypt backups and sensitive storage where required.
- Avoid sending personal, confidential, or regulated information to external model providers unless authorized.

## Limitations

Sycophancy Audit is an experimental project. Its results have several limitations:

- **Prompt sensitivity:** Small changes in wording may change model behavior.
- **Heuristic scoring:** Keyword and lexical-similarity methods can miss semantic agreement or disagreement. The wrong-answer detector is tuned to the project's geography probes; it is not a general semantic classifier.
- **Proxy metrics are not constructs:** Frame/context divergence and sampling consistency use normalized token-set overlap, not semantic equivalence. The values probe measures response-length variability within each repeated probe, not the model's values. Refusal framing combines observed refusal rate with within-run consistency; it is still a phrase-based detector. None of these alone demonstrates alignment faking or a model's underlying values.
- **Phrase-based domain probes:** The fiscal-sycophancy probe detects a narrow set of Spanish phrases and is not a tax-law evaluator.
- **False positives and negatives:** A changed answer is not necessarily sycophancy; a consistent answer is not necessarily correct. Synthetic regression cases guard against known mistakes but do not establish real-world precision or recall.
- **Provider variability:** Model versions, system instructions, sampling settings, and provider-side changes may affect results.
- **Conversation state:** Multi-turn conclusions are only valid when the test implementation actually preserves conversational history.
- **Execution failures:** Timeouts, rate limits, and provider errors can leave tests incomplete.
- **Limited benchmark coverage:** A small set of scenarios cannot represent every domain, language, or user interaction.
- **Integrity scope:** Hash-chain verification detects certain modifications but does not prove that a result is authentic or that the original model response was truthful.

For research use, publish the test definitions, scoring rules, model identifiers, execution configuration, failure counts, and relevant raw responses whenever disclosure is appropriate.

## Development and testing

Install the runtime dependencies:

```bash
python -m pip install -r requirements.txt
```

If a development requirements file is available, install it as well:

```bash
python -m pip install -r requirements-dev.txt
```

For a basic syntax check:

```bash
python -m py_compile sycophancy_api.py
```

Inspect the command-line interface:

```bash
python sycophancy_api.py --help
```

Install the development dependencies and run the deterministic regression suite:

```bash
python -m pip install -r requirements-dev.txt
python -m pytest -q
```

The unit tests use mocked response text and do not call a live LLM provider. GitHub Actions runs the suite on Python 3.10–3.13, checks application compilation and shell syntax, reports line coverage, and enforces a 50% coverage floor. The global score is reported as unavailable when any selected test has no evaluable result; inspect the coverage and excluded-result counts before comparing audits.

A successful syntax check does not guarantee correct API behavior. The regression suite covers basic bearer-token authorization, selected provider URL validation, score edge cases, SQLite round-trips and hash-chain tampering, plus SSE broadcast/replay semantics. Remaining release-hardening work includes:

- Provider retry, timeout, and rate-limit behavior with mocked transport responses.
- Conversation-history ordering and partial audit failure/status transitions.
- End-to-end SSE endpoint behavior during client disconnects and server shutdown.
- SSRF-resistant destination validation and outbound network restrictions.
- Recovery behavior when the server restarts during an audit.

Use mocked LLM responses for deterministic unit tests; reserve live provider calls for explicit integration tests.

## Project structure

The core application is organized around these files:

```text
Sycophancy-audit/
├── sycophancy_api.py    # FastAPI app, tests, LLM client, audit execution
├── requirements.txt     # Runtime dependencies
├── run.sh               # Convenience commands
├── README.md            # Project documentation
├── LICENSE              # License terms
├── .env.example         # Example configuration, if provided
└── .gitignore           # Local files and secrets, if provided
```

Optional development files such as `.env.example`, `.gitignore`, `requirements-dev.txt`, and a test directory should only be listed as part of the repository structure once they exist in the repository.

## Contributing

Contributions are welcome, especially those that improve:

- Test validity and reproducibility.
- Semantic evaluation beyond keyword matching.
- Multi-turn conversation handling.
- Error reporting and incomplete-audit status.
- Security of provider configuration and API access.
- Automated tests and documentation.

For significant changes, please include tests and describe how the change affects existing metrics or audit results.

## License

See [`LICENSE`](LICENSE) for the applicable license and terms of use.

---

**Disclaimer:** Sycophancy Audit does not establish that a model is truthful, safe, unbiased, or reliable. It provides experimental observations for further analysis and should not be used as the sole basis for model selection or safety certification.
