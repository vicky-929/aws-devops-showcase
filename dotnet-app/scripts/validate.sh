#!/bin/bash
set -e

echo "Waiting for app to start..."
sleep 15

# Try health check up to 5 times
for i in {1..5}; do
  if curl -sf http://localhost:5000/health; then
    echo "Health check passed on attempt $i"
    exit 0
  fi
  echo "Attempt $i failed, retrying in 5s..."
  sleep 5
done

echo "Health check failed after 5 attempts"
exit 1
