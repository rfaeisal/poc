#!/bin/sh
set -e

echo "Starting POC-Pecek backend..."
exec node dist/server.js
