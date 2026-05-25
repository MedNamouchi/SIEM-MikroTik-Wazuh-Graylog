# Graylog Server Setup — Ubuntu 22.04

Complete installation and configuration guide for Graylog 7.0 with MongoDB and OpenSearch.

---

## Prerequisites

- Ubuntu 22.04 LTS (minimum **8 GB RAM**)
- Administrative (sudo) access
- Network connectivity to MikroTik routers and Wazuh Manager

---

## Part 1 — Installation

### Step 1 — Set Timezone

```bash
sudo timedatectl set-timezone UTC
```

### Step 2 — Install MongoDB 8.0

MongoDB serves as the metadata database for Graylog.

```bash
# Install required tools
sudo apt-get install gnupg curl

# Import MongoDB public key
curl -fsSL https://www.mongodb.org/static/pgp/server-8.0.asc | \
  sudo gpg -o /usr/share/keyrings/mongodb-server-8.0.gpg --dearmor

# Add MongoDB repository (Ubuntu 22.04 — Jammy)
echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-8.0.gpg ] \
  https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/8.0 multiverse" | \
  sudo tee /etc/apt/sources.list.d/mongodb-org-8.0.list

# Update and install
sudo apt-get update
sudo apt-get install -y mongodb-org

# Prevent automatic upgrades
sudo apt-mark hold mongodb-org
```

Configure MongoDB to listen on all interfaces:

```bash
sudo nano /etc/mongod.conf
# Add/modify:
# net:
#   port: 27017
#   bindIpAll: true
```

Enable and start:

```bash
sudo systemctl daemon-reload
sudo systemctl enable mongod.service
sudo systemctl start mongod.service
sudo systemctl status mongod.service
```

### Step 3 — Install Graylog Data Node

```bash
# Download and install Graylog repository
wget https://packages.graylog2.org/repo/packages/graylog-7.0-repository_latest.deb
sudo dpkg -i graylog-7.0-repository_latest.deb
sudo apt-get update
sudo apt-get install graylog-datanode

# Set vm.max_map_count for OpenSearch
echo 'vm.max_map_count=262144' | \
  sudo tee -a /etc/sysctl.d/99-graylog-datanode.conf
sudo sysctl --system

# Generate password secret (save this value!)
openssl rand -hex 32
```

Configure Data Node:

```bash
sudo nano /etc/graylog/datanode/datanode.conf

# Set:
# password_secret = <YOUR_GENERATED_SECRET>
# opensearch_heap = 4g        # Half of your total RAM
# mongodb_uri = mongodb://localhost:27017/graylog
```

Start Data Node:

```bash
sudo systemctl daemon-reload
sudo systemctl enable graylog-datanode.service
sudo systemctl start graylog-datanode
sudo systemctl status graylog-datanode
```

### Step 4 — Install Graylog Server

```bash
sudo apt-get install graylog-server
```

Generate admin password hash:

```bash
echo -n "Enter Password: " && head -1 </dev/stdin | \
  tr -d '\n' | sha256sum | cut -d " " -f1
```

Configure Graylog server:

```bash
sudo nano /etc/graylog/server/server.conf

# Set:
# password_secret = <SAME_SECRET_AS_DATANODE>
# root_password_sha2 = <YOUR_PASSWORD_HASH>
# http_bind_address = 0.0.0.0:9000
# message_journal_max_age = 12h
# message_journal_max_size = 5gb
```

Configure heap:

```bash
sudo nano /etc/default/graylog-server

# Set:
# GRAYLOG_SERVER_JAVA_OPTS="-Xms2g -Xmx2g -server \
#   -XX:+UseG1GC -XX:-OmitStackTraceInFastThrow"
```

Start Graylog:

```bash
sudo systemctl daemon-reload
sudo systemctl enable graylog-server.service
sudo systemctl start graylog-server.service
sudo systemctl status graylog-server.service
```

> Access Graylog at `http://YOUR_SERVER_IP:9000`  
> On first login, get preflight credentials with:
> ```bash
> sudo journalctl -u graylog-server | grep -i "password"
> ```

---

## Part 2 — TLS Certificate

### Step 5 — Generate Certificate for MikroTik TLS

> ⚠️ The certificate MUST include `extendedKeyUsage=serverAuth` and
> `keyUsage=digitalSignature,keyEncipherment`.
> Without these, RouterOS 7.23+ will NOT show TLS as an available protocol.

```bash
sudo mkdir -p /etc/graylog/server/certs
cd /etc/graylog/server/certs

sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout /etc/graylog/server/certs/graylog.key \
  -out /etc/graylog/server/certs/graylog.crt \
  -subj "/CN=graylog" \
  -addext "extendedKeyUsage=serverAuth" \
  -addext "keyUsage=digitalSignature,keyEncipherment"

# Set correct permissions
sudo chown graylog:graylog /etc/graylog/server/certs/graylog.key
sudo chown graylog:graylog /etc/graylog/server/certs/graylog.crt
sudo chmod 600 /etc/graylog/server/certs/graylog.key

sudo systemctl restart graylog-server
```

---

## Part 3 — CEF Input Configuration

### Step 6 — Create CEF TCP Input with TLS

1. Open Graylog: `http://YOUR_IP:9000`
2. Navigate to **System → Inputs**
3. Select **CEF TCP** → click **Launch new input**
4. Configure:

| Field | Value |
|-------|-------|
| Title | `MikroTik CEF TLS` |
| Bind address | `0.0.0.0` |
| Port | `6514` |
| Timezone | `UTC` |
| TLS cert file | `/etc/graylog/server/certs/graylog.crt` |
| TLS private key file | `/etc/graylog/server/certs/graylog.key` |
| Enable TLS | ✅ checked |

Verify Graylog is listening:

```bash
sudo ss -tulnp | grep 6514
# Expected: tcp LISTEN 0 4096 *:6514 *:* users:(("java",...))
```

---

## Part 4 — Streams

Streams classify incoming logs before forwarding them to Wazuh.

| Stream | Rule | Description |
|--------|------|-------------|
| `MikroTik Main Stream` | `device_vendor = MikroTik` | All MikroTik events |
| `MikroTik Firewall Events` | message contains `[FW]` | Firewall rule hits |
| `MikroTik SYS-AUTH / LOGIN Events` | message contains `[SYS]` + auth keywords | Authentication events |
| `MikroTik Login Info Stream` | message contains `logged in` or `logged out` | Session tracking |
| `MikroTik Info Events (filtered)` | message contains `[INFO]` + `memory\|cpu` | Resource metrics |
| `MikroTik SYS-SYSTEM Events` | message contains `reboot\|config\|added\|removed` | System changes |

---

## Part 5 — Syslog Output to Wazuh

### Step 7 — Install Syslog Output Plugin

The open-source Graylog only includes GELF and STDOUT outputs natively.
A community plugin is required to forward logs in syslog format.

```bash
wget https://github.com/wizecore/graylog2-output-syslog/releases/\
latest/download/graylog-output-syslog-6.3.5.jar

sudo cp graylog-output-syslog-6.3.5.jar /usr/share/graylog-server/plugin/
sudo systemctl restart graylog-server
```

After restart, a new **Syslog** output type appears in **System → Outputs**.

### Step 8 — Configure rsyslog

```bash
sudo nano /etc/rsyslog.d/graylog-wazuh.conf
```

```
module(load="imtcp")
input(type="imtcp" port="514")

if $fromhost-ip == '127.0.0.1' then /var/log/mikrotik.log
& stop
```

```bash
sudo systemctl restart rsyslog
sudo ss -tulnp | grep 514
# Expected: tcp LISTEN 0 25 0.0.0.0:514 ... rsyslogd
```

### Step 9 — Create Graylog Syslog Output

1. Navigate to **System → Outputs**
2. Select **Syslog Output** → click **Launch new output**
3. Configure:

| Field | Value |
|-------|-------|
| Title | `Wazuh Agent Local` |
| Protocol | `TCP` |
| Remote host | `127.0.0.1` |
| Syslog port | `514` |
| Message format | `full` |

> ⚠️ Use `full` format (not `plain`) to preserve the `msg: MKT[...]` field
> that Wazuh decoders need for parsing.

### Step 10 — Assign Output to Stream

1. Navigate to **Streams**
2. Find **Default Stream**
3. Click **More Actions → Manage Outputs**
4. Select **Wazuh Agent Local**

> ⚠️ An output will NOT forward messages unless it is assigned to a stream.

---

## Verification

```bash
# Check all services
sudo systemctl status graylog-server graylog-datanode mongod rsyslog

# Check all ports
sudo ss -tulnp | grep -E "514|6514|9000"

# Monitor log file
sudo tail -f /var/log/mikrotik.log | grep MKT
```
