#!/bin/bash
set -e

APP_DIR=/var/www/dotnet-app/app

# Find the executable (self-contained publish creates binary named after project)
APP_BIN=$(find $APP_DIR -maxdepth 1 -type f -executable ! -name "*.so" ! -name "*.dll" | head -1)

if [ -z "$APP_BIN" ]; then
  # Fallback: run via dotnet
  APP_BIN="dotnet $APP_DIR/dotnet-app.dll"
fi

echo "Starting app: $APP_BIN"

# Create systemd service
cat > /etc/systemd/system/dotnet-app.service << SERVICE
[Unit]
Description=.NET App Blue/Green Demo
After=network.target

[Service]
WorkingDirectory=$APP_DIR
ExecStart=$APP_BIN
Restart=always
RestartSec=5
User=root
Environment=ASPNETCORE_ENVIRONMENT=Production
Environment=ASPNETCORE_URLS=http://0.0.0.0:5000

[Install]
WantedBy=multi-user.target
SERVICE

systemctl daemon-reload
systemctl enable dotnet-app
systemctl restart dotnet-app
