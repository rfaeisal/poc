#!/bin/bash
set -e

cd "$(dirname "$0")/.."
source .env

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="./backups"
mkdir -p "$BACKUP_DIR"

echo "Backing up database..."
docker compose exec -T postgres pg_dump \
    -U "$POSTGRES_USER" \
    -d "$POSTGRES_DB" \
    --no-owner \
    --no-acl \
    | gzip > "$BACKUP_DIR/pocpecek_$TIMESTAMP.sql.gz"

echo "Backup saved: $BACKUP_DIR/pocpecek_$TIMESTAMP.sql.gz"

# Hapus backup lebih dari 30 hari
find "$BACKUP_DIR" -name "*.sql.gz" -mtime +30 -delete
echo "Old backups cleaned up"
