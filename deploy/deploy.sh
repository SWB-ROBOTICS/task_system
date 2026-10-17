#!/usr/bin/env bash
# Reference copy of /srv/stacks/task-system/deploy.sh. Run by GitHub Actions over SSH
# (forced command) on push to main. Same pattern as the swbai-fleet stack: tag the
# current image :previous, build, deploy, watch a stabilization window, roll back on failure.
set -euo pipefail
cd /srv/stacks/task-system

STABILIZE_SECONDS=20

echo "==> Pulling latest source"
git -C app fetch -q origin main
git -C app checkout -q main
git -C app pull -q --ff-only origin main

echo "==> Tagging current image as :previous (rollback point)"
if docker image inspect task-system:latest >/dev/null 2>&1; then
  docker tag task-system:latest task-system:previous
fi

echo "==> Building and deploying"
docker compose build app
docker compose up -d app

echo "==> Waiting ${STABILIZE_SECONDS}s to confirm stability"
sleep "$STABILIZE_SECONDS"

status=$(docker compose ps app --format '{{.Status}}' || echo missing)
restarts=$(docker inspect --format='{{.RestartCount}}' task-system 2>/dev/null || echo 0)
echo "app: $status (restarts: $restarts)"
if ! echo "$status" | grep -qi 'healthy\|up' || echo "$status" | grep -qi unhealthy || [ "$restarts" -gt 0 ]; then
  echo "==> Unstable, rolling back to :previous"
  if docker image inspect task-system:previous >/dev/null 2>&1; then
    docker tag task-system:previous task-system:latest
    docker compose up -d app
  fi
  echo "==> Rolled back. Deploy FAILED."
  exit 1
fi
echo "==> Deploy stable and healthy."
