# DataMind AI

AI-powered Oracle database intelligence platform: PL/SQL data-quality engine, duplicate detection, SQL performance monitoring, anomaly detection and AI-assisted incident analysis.

**Stack:** Oracle PL/SQL · Python / FastAPI · React · LLM API (provider TBD)

> Status: Phase 1 — Oracle foundation (in progress)

## Repository layout

| Folder | Contents |
|---|---|
| `database/` | Numbered SQL install scripts (schema, packages, seed data, tests) |
| `ai-service/` | FastAPI service for AI orchestration |
| `frontend/` | React dashboard |
| `documentation/` | Requirements, architecture, API and benchmark docs |
| `sample-data/` | Synthetic customer CSV/JSON |

## Local setup

**Prerequisites:** Oracle AI Database 26ai Free (Windows), Git, Python 3.10+, Node.js.

1. Create the schema (prompts for a password, input hidden):
   ```
   sqlplus / as sysdba @database/00_setup/01_create_schema.sql
   ```
2. Copy `.env.example` to `.env` and set `ORACLE_PASSWORD` (avoid `@`, quotes and `$` — sqlplus treats `@` as the start of a server address).
3. Connect: `sqlplus DATAMIND_AI@127.0.0.1:1521/FREEPDB1`
