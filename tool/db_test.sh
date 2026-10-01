#!/usr/bin/env bash
# Runs the database test-suite against a real PostgreSQL 16.
#
#   tool/db_test.sh            # throwaway local cluster, run all DB tests
#   tool/db_test.sh --scale    # also load 10k/5k/50k scale data and run perf checks
#
# If DATABASE_URL is set (CI service container), it is used as the admin
# connection instead of starting a local cluster.
#
# Steps: build template DB `vepari_template` = Supabase shim + all migrations,
# then `dart test` in backend_tests/ (each test file clones the template).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SCALE=0
for arg in "$@"; do
  case "$arg" in
    --scale) SCALE=1 ;;
    *) echo "unknown argument: $arg" >&2; exit 2 ;;
  esac
done

PG_BIN="${PG_BIN:-/usr/lib/postgresql/16/bin}"
CLUSTER_DIR=""

as_pg() {
  if [ "$(id -u)" = "0" ]; then runuser -u postgres -- "$@"; else "$@"; fi
}

cleanup() {
  if [ -n "$CLUSTER_DIR" ]; then
    as_pg "$PG_BIN/pg_ctl" -D "$CLUSTER_DIR/data" -m immediate stop >/dev/null 2>&1 || true
    rm -rf "$CLUSTER_DIR"
  fi
}
trap cleanup EXIT

if [ -z "${DATABASE_URL:-}" ]; then
  CLUSTER_DIR="$(mktemp -d /tmp/vepari-pg.XXXXXX)"
  chmod 755 "$CLUSTER_DIR"
  [ "$(id -u)" = "0" ] && chown postgres "$CLUSTER_DIR"
  PORT="${PGPORT_TEST:-54329}"
  as_pg "$PG_BIN/initdb" -D "$CLUSTER_DIR/data" -U postgres --auth=trust -E UTF8 --locale=C.UTF-8 >/dev/null
  as_pg "$PG_BIN/pg_ctl" -D "$CLUSTER_DIR/data" -l "$CLUSTER_DIR/pg.log" -w \
    -o "-p $PORT -k $CLUSTER_DIR -c listen_addresses=127.0.0.1 -c max_connections=200 -c shared_buffers=256MB" start >/dev/null
  export DATABASE_URL="postgres://postgres@127.0.0.1:$PORT/postgres"
fi

psql_admin() { psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -q -X "$@"; }

echo "==> building template database"
psql_admin -c "drop database if exists vepari_template" -c "create database vepari_template"
TEMPLATE_URL="${DATABASE_URL%/*}/vepari_template"
psql "$TEMPLATE_URL" -v ON_ERROR_STOP=1 -q -X -f "$ROOT/supabase/tests/shim/supabase_shim.sql"
for f in "$ROOT"/supabase/migrations/*.sql; do
  echo "    migrate $(basename "$f")"
  psql "$TEMPLATE_URL" -v ON_ERROR_STOP=1 -q -X -f "$f"
done

export VEPARI_ADMIN_URL="$DATABASE_URL"
export VEPARI_TEMPLATE_DB="vepari_template"
export VEPARI_SCALE="$SCALE"

echo "==> running DB tests"
cd "$ROOT/backend_tests"
dart pub get >/dev/null
dart test --reporter expanded --concurrency=4
