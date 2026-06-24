#!/bin/bash
set -e

APP_DIR=/var/www/dotnet-app/app

# The binary is always named after the project — dotnet-app
APP_BIN=$APP_DIR/dotnet-app

if [ ! -f "$APP_BIN" ]; then
  echo "Binary not found at $APP_BIN, listing directory:"
  ls -la $APP_DIR
  exit 1
fi

chmod +x $APP_BIN

# Create systemd service with explicit binary path
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

# Wait and verify it started
sleep 5
systemctl status dotnet-app
