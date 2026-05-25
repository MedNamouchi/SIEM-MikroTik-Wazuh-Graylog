# SIEM-MikroTik-Wazuh-Graylog
End-to-end SIEM deployment with MikroTik, Wazuh and Graylog — EVE-NG lab + production
# 🛡️ MikroTik + Graylog + Wazuh SIEM — End-to-End Log Pipeline

> Centralized, encrypted log collection from MikroTik routers to a full SIEM stack with automated threat detection and alerting.

![Status](https://img.shields.io/badge/Phase%201-EVE--NG%20Lab%20%E2%9C%85-brightgreen)
![Status](https://img.shields.io/badge/Phase%202-Production%20🚧-orange)
![RouterOS](https://img.shields.io/badge/RouterOS-7.23+-blue)
![Wazuh](https://img.shields.io/badge/Wazuh-4.x-blue)
![Graylog](https://img.shields.io/badge/Graylog-7.0-orange)
![License](https://img.shields.io/badge/License-MIT-green)

---

## 📌 Overview

This project documents a **production-grade SIEM pipeline** that collects security logs from **6 MikroTik CHR routers**, forwards them securely to **Graylog** for visualization and filtering, then routes them to **Wazuh** for threat detection, correlation, and automated alerting.

Built and tested during a cybersecurity internship at **OFIR LTD — Osijek, Croatia (April–August 2026)**.

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────┐
│                   EVE-NG Lab                        │
│                                                     │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐          │
│  │ MKT[001] │  │ MKT[002] │  │ MKT[003] │          │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘          │
│  ┌────┴─────┐  ┌────┴─────┐  ┌────┴─────┐          │
│  │ MKT[004] │  │ MKT[005] │  │ MKT[006] │          │
│  └──────────┘  └──────────┘  └──────────┘          │
│        │              │              │              │
│        └──────────────┴──────────────┘              │
│                       │                             │
│              CEF over TLS (port 6514)               │
│                       │                             │
│        ┌──────────────▼──────────────────────┐      │
│        │         Ubuntu 22.04 Server         │      │
│        │                                     │      │
│        │  ┌─────────────────────────────┐    │      │
│        │  │  Graylog 7.0                │    │      │
│        │  │  + MongoDB (metadata)       │    │      │
│        │  │  + OpenSearch (storage)     │    │      │
│        │  │  + Streams & Rules          │    │      │
│        │  └──────────────┬──────────────┘    │      │
│        │                 │                   │      │
│        │       Syslog TCP localhost:514       │      │
│        │       (never exposed to network)    │      │
│        │                 │                   │      │
│        │  ┌──────────────▼──────────────┐    │      │
│        │  │  rsyslog                    │    │      │
│        │  │  → /var/log/mikrotik.log    │    │      │
│        │  └──────────────┬──────────────┘    │      │
│        │                 │                   │      │
│        │  ┌──────────────▼──────────────┐    │      │
│        │  │  Wazuh Agent                │    │      │
│        │  │  reads mikrotik.log         │    │      │
│        │  └──────────────┬──────────────┘    │      │
│        └─────────────────┼───────────────────┘      │
└─────────────────────────┼───────────────────────────┘
                          │
                  AES-256 encrypted
                          │
             ┌────────────▼────────────┐
             │      Wazuh Manager      │
             │  Custom Decoders+Rules  │
             │  Threat Detection       │
             │  Active Response        │
             └────────────┬────────────┘
                          │
              ┌───────────┴───────────┐
              │                       │
         📧 Email Alert        💬 Mattermost
```

---

## 🔄 Log Flow — Step by Step

| Step | Component | Action |
|------|-----------|--------|
| 1 | MikroTik CHR (x6) | Generates logs (firewall, system, info) and sends them in **CEF format over TLS** to Graylog on port **6514** |
| 2 | Graylog | Receives, parses, and stores logs in **OpenSearch** for visualization |
| 3 | Graylog Streams | Classifies logs using **rules and streams** by topic (FW, SYS, AUTH, INFO) |
| 4 | Graylog Syslog Output | Forwards logs to **rsyslog on localhost:514** via TCP (never exposed to network) |
| 5 | rsyslog | Writes logs to `/var/log/mikrotik.log` |
| 6 | Wazuh Agent | Reads the log file and forwards events to **Wazuh Manager encrypted with AES-256** |
| 7 | Wazuh Manager | Applies **custom decoders and rules** for threat detection and alerting |
| 8 | Active Response | Sends **email + Mattermost** notifications on brute force detection |

---

## 📊 Graylog Streams

| Stream | Description |
|--------|-------------|
| `MikroTik Main Stream` | All MikroTik events (all routers, all topics) |
| `MikroTik Firewall Events` | Events tagged with `[FW]` — firewall rules hits |
| `MikroTik SYS-AUTH / LOGIN Events` | Authentication and login events |
| `MikroTik Login Info Stream` | Events tagged with `LOGGED IN` or `LOGGED OUT` |
| `MikroTik Info Events (filtered)` | `[INFO]` events filtered for `memory\|cpu` metrics |
| `MikroTik SYS-SYSTEM Events` | System events: `reboot\|config\|added\|removed` |

---

## 🔑 Key Technical Discoveries

> These are hard-won lessons from debugging the pipeline — not found in official docs.

- **TLS certificate must include `extendedKeyUsage=serverAuth`** — without this extension, RouterOS 7.x will not display TLS as an available protocol option. The connection fails silently.
- **`remote-protocol=tls` must be set in the `add` command** — RouterOS returns a syntax error if you try to set it afterwards with `set`. Delete and recreate the logging action if needed.
- **Graylog output format must be `full`** — the `plain` format strips the `msg: MKT[...]` field that Wazuh decoders use for parsing. Nothing will match.
- **Localhost channel is secure by design** — the TCP connection between Graylog and rsyslog stays on `127.0.0.1` and never leaves the machine, eliminating sniffing risk.
- **Two copies of logs, two purposes** — Graylog keeps one copy in OpenSearch for visualization and dashboards; Wazuh gets its own copy for security analysis and correlation.
- **Active response script must use `timeout 3 cat`** — using plain `cat` causes a deadlock because the script waits indefinitely for stdin to close.

---

## 🗂️ Repository Structure

```
SIEM-MikroTik-Wazuh-Graylog/
│
├── README.md
├── architecture/
│   └── diagram.png                    # Full pipeline architecture diagram
│
├── mikrotik/
│   ├── cef-tls-config.md             # CEF over TLS logging action setup
│   └── syslog-udp-config.md          # Logging topics and prefix format
│
├── wazuh/
│   ├── decoders/
│   │   └── mikrotik-decoder.xml      # Custom decoders (auth failure, login)
│   ├── rules/
│   │   └── mikrotik-rules.xml        # Correlation rules (brute force detection)
│   └── screenshots/                  # Wazuh dashboard screenshots
│
├── graylog/
│   ├── screenshots/                  # Input, streams, output configuration
│   └── setup.md                      # Graylog installation and plugin setup
│
├── rsyslog/
│   └── graylog-wazuh.conf            # rsyslog config for localhost forwarding
│
└── docs/
    └── technical-report.pdf          # Full step-by-step technical guide
```

---

## ⚙️ Prerequisites

| Component | Version | Notes |
|-----------|---------|-------|
| MikroTik RouterOS | **7.23+** | TLS support for CEF logging requires 7.23 minimum |
| Ubuntu Server | 22.04 LTS | Hosts Graylog, rsyslog, and Wazuh Agent |
| Graylog | 7.0 | + MongoDB (metadata) + OpenSearch (storage) |
| Wazuh Manager | 4.x | Separate server |
| RAM (Graylog server) | 8 GB minimum | OpenSearch requires 4 GB heap |

---

## 🚀 Quick Start

> Full step-by-step instructions are in [`docs/technical-report.pdf`](docs/technical-report.pdf)

### 1. Generate TLS Certificate
```bash
sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout /etc/graylog/server/certs/graylog.key \
  -out /etc/graylog/server/certs/graylog.crt \
  -subj "/CN=graylog" \
  -addext "extendedKeyUsage=serverAuth" \
  -addext "keyUsage=digitalSignature,keyEncipherment"
```

### 2. Configure MikroTik Logging
```routeros
# CRITICAL: remote-protocol=tls must be in the add command
/system logging action add \
  name=graylogcef \
  target=remote \
  remote=GRAYLOG_IP \
  remote-port=6514 \
  remote-log-format=cef \
  remote-protocol=tls

/system logging add topics=firewall prefix="MKT[001][FW]" action=graylogcef
/system logging add topics=system prefix="MKT[001][SYS]" action=graylogcef
/system logging add topics=info prefix="MKT[001][INFO]" action=graylogcef
```

### 3. Configure rsyslog
```bash
# /etc/rsyslog.d/graylog-wazuh.conf
module(load="imtcp")
input(type="imtcp" port="514")

if $fromhost-ip == '127.0.0.1' then /var/log/mikrotik.log
& stop
```

### 4. Configure Wazuh Agent
```xml
<!-- /var/ossec/etc/ossec.conf -->
<localfile>
  <log_format>syslog</log_format>
  <location>/var/log/mikrotik.log</location>
</localfile>
```

### 5. Verify the Pipeline
```bash
# Check all services
sudo systemctl status graylog-server graylog-datanode mongod rsyslog wazuh-agent

# Monitor log file in real time
sudo tail -f /var/log/mikrotik.log | grep MKT

# Test Wazuh decoder
sudo /var/ossec/bin/wazuh-logtest
```

---

## 🔍 Wazuh Decoder — Sample Output

```
Input log:
Apr 30 08:45:07 ubuntu22 unknown source: 172.30.2.38 |
message: CHR: [10, High] { msg: MKT[001][SYS]: login failure
for user admin from 172.30.3.71 via winbox | device_vendor: MikroTik }

Decoder output:
  name:           mikrotik_graylog_auth_failure
  router_id:      001
  log_type:       SYS
  act:            login failure
  user:           admin
  srcip:          172.30.3.71
  access_method:  winbox
```

---

## 🚨 Active Response — Brute Force Alert

When Wazuh rule `110015` fires (brute force detected), the active response script automatically sends:

**Email subject:**
```
[WAZUH] BRUTE FORCE MikroTik - Level 12 - Router MKT[004] - IP 172.30.3.71
```

**Mattermost notification:**
```
WAZUH BRUTE FORCE ALERT
Level: 12 | Router: MKT[004] | Source IP: 172.30.3.71
User: admin | Rule: MikroTik: Possible brute force attack
```

---

## 🛠️ Troubleshooting

| Issue | Cause | Fix |
|-------|-------|-----|
| TLS not available in RouterOS | Missing `tls-server` in cert | Regenerate with `extendedKeyUsage=serverAuth` |
| `syntax error` on `remote-protocol=tls` | Used `set` instead of `add` | Delete action, recreate with `add` |
| No logs in `mikrotik.log` | Graylog output not assigned to stream | Assign output to Default Stream |
| Logs in file but not in Wazuh | Wrong `localfile` path | Check `ossec.conf` localfile location |
| Decoder not matching | Wrong prematch or format | Use `wazuh-logtest` to debug |
| Active response not triggering | `cat` deadlock in script | Use `timeout 3 cat` |
| Plugin output strips fields | Using `plain` format | Switch Graylog output format to `full` |

---

## 👤 Author

**Mohamed Amine Namouchi**
Élève Ingénieur — Sécurité et Qualité des Réseaux, Polytech Dijon

[![LinkedIn](https://img.shields.io/badge/LinkedIn-namouchimohamedamine-blue?logo=linkedin)](https://linkedin.com/in/namouchimohamedamine)
[![GitHub](https://img.shields.io/badge/GitHub-MedNamouchi-black?logo=github)](https://github.com/MedNamouchi)

---

## 📄 License

MIT — feel free to use, adapt, and share with attribution.
