#!/bin/bash
# Stop existing app if running
systemctl stop dotnet-app 2>/dev/null || true
# Clean old deployment
rm -rf /var/www/dotnet-app
mkdir -p /var/www/dotnet-app
