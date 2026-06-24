#!/bin/bash
# Set permissions
chown -R ec2-user:ec2-user /var/www/dotnet-app
chmod +x /var/www/dotnet-app/dotnet-app 2>/dev/null || true

# Create systemd service for the .NET app
cat > /etc/systemd/system/dotnet-app.service << 'SERVICE'
[Unit]
Description=.NET App Blue/Green Demo
After=network.target

[Service]
WorkingDirectory=/var/www/dotnet-app
ExecStart=/var/www/dotnet-app/dotnet-app
Restart=always
RestartSec=5
User=ec2-user
Environment=ASPNETCORE_ENVIRONMENT=Production
Environment=ASPNETCORE_URLS=http://0.0.0.0:5000

[Install]
WantedBy=multi-user.target
SERVICE

systemctl daemon-reload
