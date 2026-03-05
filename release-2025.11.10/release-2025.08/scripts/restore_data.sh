#!/usr/bin/env bash
# restore_data.sh - Restore Postgres data for HAPI & Keycloak via Docker on Ubuntu/Linux.
# Usage:
#   ./restore_data.sh [HAPI_SQL_FILE] [KEYCLOAK_SQL_FILE]
# Defaults:
#   HAPI_SQL_FILE=hapi_data.sql
#   KEYCLOAK_SQL_FILE=keycloak_data.sql
#
# Requires:
#   - bash, docker, and either 'docker compose' or 'docker-compose'
#   - A .env file in the working directory containing:
#       PG_HAPI_USER, PG_HAPI_DB, PG_KC_USER, PG_KC_DB
#
# This script mirrors the behavior of the original PowerShell restore_data.ps1.

set -euo pipefail

HAPI_SQL="${1:-hapi_data.sql}"
KC_SQL="${2:-keycloak_data.sql}"

# --- helper: load .env into environment (skip comments/blank lines) ---
load_dotenv() {
  local line key val
  while IFS= read -r line || [[ -n "$line" ]]; do
    # skip comments & blank lines
    [[ -z "${line// }" ]] && continue
    [[ "$line" =~ ^[[:space:]]*# ]] && continue
    # key=value
    if [[ "$line" =~ ^[[:space:]]*([A-Za-z_][A-Za-z0-9_]*)[[:space:]]*=[[:space:]]*(.*)$ ]]; then
      key="${BASH_REMATCH[1]}"
      val="${BASH_REMATCH[2]}"
      # strip surrounding quotes if any
      if [[ "$val" =~ ^\"(.*)\"[[:space:]]*$ ]]; then
        val="${BASH_REMATCH[1]}"
      elif [[ "$val" =~ ^\'(.*)\'[[:space:]]*$ ]]; then
        val="${BASH_REMATCH[1]}"
      else
        # trim trailing spaces
        val="${val%%[[:space:]]*}"
      fi
      export "${key}=${val}"
    fi
  done < ".env"
}

# --- choose docker compose command ---
choose_compose() {
  if docker compose version >/dev/null 2>&1; then
    echo "docker compose"
  elif command -v docker-compose >/dev/null 2>&1; then
    echo "docker-compose"
  else
    echo "ERROR: Neither 'docker compose' nor 'docker-compose' is available." >&2
    exit 1
  fi
}

# --- main ---

# check sql files exist
[[ -f "$HAPI_SQL" ]] || { echo "ERROR: SQL file not found: $HAPI_SQL" >&2; exit 1; }
[[ -f "$KC_SQL"   ]] || { echo "ERROR: SQL file not found: $KC_SQL"   >&2; exit 1; }

# load env
if [[ -f ".env" ]]; then
  load_dotenv
else
  echo "WARNING: .env not found in current directory. Expecting env vars to be present." >&2
fi

# ensure required env vars exist
: "${PG_HAPI_USER:?PG_HAPI_USER is required (from .env)}"
: "${PG_HAPI_DB:?PG_HAPI_DB is required (from .env)}"
: "${PG_KC_USER:?PG_KC_USER is required (from .env)}"
: "${PG_KC_DB:?PG_KC_DB is required (from .env)}"

DC=$(choose_compose)

# get container ids for pg-hapi and pg-keycloak services
pg_hapi_id="$($DC ps -q pg-hapi)"
pg_kc_id="$($DC ps -q pg-keycloak)"

[[ -n "$pg_hapi_id" ]] || { echo "ERROR: Could not find running container for service 'pg-hapi'." >&2; exit 1; }
[[ -n "$pg_kc_id"   ]] || { echo "ERROR: Could not find running container for service 'pg-keycloak'." >&2; exit 1; }

echo "Restore HAPI from $HAPI_SQL ..."
docker exec -i "$pg_hapi_id" psql -U "$PG_HAPI_USER" -d "$PG_HAPI_DB" < "$HAPI_SQL"

echo "Restore Keycloak from $KC_SQL ..."
docker exec -i "$pg_kc_id"   psql -U "$PG_KC_USER"   -d "$PG_KC_DB"   < "$KC_SQL"

echo "Done."
