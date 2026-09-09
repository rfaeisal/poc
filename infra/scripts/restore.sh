#!/bin/bash
set -e

cd "$(dirname "$0")/.."
source .env

BACKUP_FILE=$1
if [ -z "$BACKUP_FILE" ]; then
    echo "Usage: bash scripts/restore.sh backups/pocpecek_YYYYMMDD_HHMMSS.sql.gz"
    echo ""
    echo "Available backups:"
    ls -lh backups/*.sql.gz 2>/dev/null || echo "  (tidak ada backup)"
    exit 1
fi

if [ ! -f "$BACKUP_FILE" ]; then
    echo "File tidak ditemukan: $BACKUP_FILE"
    exit 1
fi

echo "PERINGATAN: Ini akan menghapus semua data di database $POSTGRES_DB dan menggantinya dengan backup."
read -p "Lanjutkan? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Dibatalkan."
    exit 0
fi

echo "Restoring dari $BACKUP_FILE..."

docker compose exec -T postgres psql -U "$POSTGRES_USER" -d postgres -c \
    "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname='$POSTGRES_DB' AND pid <> pg_backend_pid();" 2>/dev/null

docker compose exec -T postgres dropdb -U "$POSTGRES_USER" --if-exists "$POSTGRES_DB"
docker compose exec -T postgres createdb -U "$POSTGRES_USER" "$POSTGRES_DB"

gunzip -c "$BACKUP_FILE" | docker compose exec -T postgres psql -U "$POSTGRES_USER" -d "$POSTGRES_DB"

echo "Restore selesai dari: $BACKUP_FILE"
