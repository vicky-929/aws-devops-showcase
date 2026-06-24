#!/bin/bash
# Wait for app to start
sleep 5
# Health check — if fails, CodeDeploy auto-rollbacks
curl -f http://localhost:5000/health || exit 1
echo "Health check passed"
