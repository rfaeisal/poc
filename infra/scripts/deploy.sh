#!/bin/bash
set -e

cd "$(dirname "$0")/.."
source .env

SERVICE=$1

if [ -z "$SERVICE" ]; then
    echo "Deploy ulang semua service..."
    docker compose pull
    docker compose up -d
    echo "Semua service di-deploy ulang."
else
    echo "Deploy ulang service: $SERVICE"
    docker compose pull "$SERVICE"
    docker compose up -d --no-deps "$SERVICE"
    echo "Service $SERVICE di-deploy ulang."
fi

docker compose ps
