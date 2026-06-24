#!/bin/bash
set -e

mkdir -p /var/www/dotnet-app/app
chown -R root:root /var/www/dotnet-app

# Make all files in app dir executable
chmod -R 755 /var/www/dotnet-app/app

# Create systemd service file placeholder
cat > /etc/systemd/system/dotnet-app.service << SERVICE
[Unit]
Description=.NET App Demo
After=network.target

[Service]
WorkingDirectory=/var/www/dotnet-app/app
ExecStart=/var/www/dotnet-app/app/dotnet-app
Restart=always
User=root
Environment=ASPNETCORE_URLS=http://0.0.0.0:5000

[Install]
WantedBy=multi-user.target
SERVICE

systemctl daemon-reload
