#!/bin/bash
set -e

APP_DIR=/var/www/dotnet-app/app

# Framework-dependent — run with dotnet command
cat > /etc/systemd/system/dotnet-app.service << SERVICE
[Unit]
Description=.NET App Demo
After=network.target

[Service]
WorkingDirectory=$APP_DIR
ExecStart=/usr/bin/dotnet $APP_DIR/dotnet-app.dll
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
sleep 5
systemctl status dotnet-app
