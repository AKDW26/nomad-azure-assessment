#!/bin/bash
# scripts/install-nomad-server.sh
set -e

# Update system
apt-get update
apt-get install -y unzip curl

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
usermod -aG docker adminuser

# Install Nomad
cd /tmp
curl -O https://releases.hashicorp.com/nomad/1.6.1/nomad_1.6.1_linux_amd64.zip
unzip nomad_1.6.1_linux_amd64.zip
mv nomad /usr/local/bin/
chmod +x /usr/local/bin/nomad

# Create nomad user and directories
useradd --system --home /etc/nomad.d --shell /bin/false nomad
mkdir -p /opt/nomad/data
mkdir -p /etc/nomad.d
chown -R nomad:nomad /opt/nomad/
chown -R nomad:nomad /etc/nomad.d/

# Create server configuration
cat > /etc/nomad.d/server.hcl << 'EOF'
datacenter = "azure-central-india"
data_dir = "/opt/nomad/data"
log_level = "INFO"

bind_addr = "0.0.0.0"

server {
  enabled = true
  bootstrap_expect = 1
}

ui_config {
  enabled = true
}

connect {
  enabled = true
}

ports {
  grpc = 4647
  http = 4646
  rpc = 4647
  serf = 4648
}

client {
  enabled = true
}
EOF

# Create systemd service
cat > /etc/systemd/system/nomad.service << 'EOF'
[Unit]
Description=Nomad
Documentation=https://www.nomadproject.io/
Requires=network-online.target
After=network-online.target
ConditionFileNotEmpty=/etc/nomad.d/server.hcl

[Service]
Type=notify
User=nomad
Group=nomad
ExecStart=/usr/local/bin/nomad agent -config=/etc/nomad.d/server.hcl
ExecReload=/bin/kill -HUP $MAINPID
KillMode=process
Restart=on-failure
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF

# Start Nomad
systemctl daemon-reload
systemctl enable nomad
systemctl start nomad
