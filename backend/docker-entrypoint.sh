#!/bin/sh
set -e

echo "Running Prisma migrations..."
npx prisma migrate deploy || echo "Migration skipped (may already be applied)"

echo "Starting server..."
exec node dist/server.js
