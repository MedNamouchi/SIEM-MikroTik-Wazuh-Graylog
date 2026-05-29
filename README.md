# 🛡️ MikroTik + Graylog + Wazuh SIEM — End-to-End Log Pipeline

> Centralized, encrypted log collection from MikroTik routers to a full SIEM stack with automated threat detection and alerting.

![Phase 1](https://img.shields.io/badge/Phase%201-EVE--NG%20Lab%20✅-brightgreen)
![Phase 2](https://img.shields.io/badge/Phase%202-Production%20✅-brightgreen)
![RouterOS](https://img.shields.io/badge/RouterOS-7.23+-blue)
![Wazuh](https://img.shields.io/badge/Wazuh-4.x-blue)
![Graylog](https://img.shields.io/badge/Graylog-7.0-orange)
![License](https://img.shields.io/badge/License-MIT-green)

---

## 📌 Overview

This project documents a **production-grade SIEM pipeline** that collects security logs from MikroTik routers, forwards them securely to **Graylog** for visualization and filtering, then routes them to **Wazuh** for threat detection, correlation, and automated alerting.

Built during a cybersecurity internship at **OFIR LTD — Osijek, Croatia (April–August 2026)**.

| | Phase 1 | Phase 2 |
|---|---|---|
| **Environment** | EVE-NG (virtual) | Production (physical) |
| **Routers** | 6x MikroTik CHR | Physical CCR routers |
| **Router identity** | Numeric IDs `MKT[001]` | Real names `OFIR_MAIN_NEW` |
| **Decoders** | Auth + Firewall + System | + Reboot + Config + Resources + Firewall detailed |
| **Rules** | Brute force + System | + Port scan + VPN + External traffic + CPU/RAM |
| **Status** | ✅ Complete | ✅ Complete |

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────┐
│              EVE-NG (P1) / Production (P2)          │
│                                                     │
│  ┌──────────────────────────────────────────────┐   │
│  │  MikroTik Routers                            │   │
│  │  P1: MKT[001]–MKT[006] (CHR virtual)        │   │
│  │  P2: Physical CCR (real router names)        │   │
│  └───────────────────┬──────────────────────────┘   │
│                      │                              │
│             CEF over TLS (port 6514)                │
│                      │                              │
│  ┌───────────────────▼──────────────────────────┐   │
│  │         Ubuntu 22.04 Server                  │   │
│  │                                              │   │
│  │  ┌────────────────────────────────────────┐  │   │
│  │  │  Graylog 7.0                           │  │   │
│  │  │  + MongoDB (metadata)                  │  │   │
│  │  │  + OpenSearch (storage)                │  │   │
│  │  │  + Streams & Rules                     │  │   │
│  │  └───────────────┬────────────────────────┘  │   │
│  │                  │ Syslog TCP localhost:514   │   │
│  │  ┌───────────────▼────────────────────────┐  │   │
│  │  │  rsyslog → /var/log/mikrotik.log       │  │   │
│  │  └───────────────┬────────────────────────┘  │   │
│  │  ┌───────────────▼────────────────────────┐  │   │
│  │  │  Wazuh Agent                           │  │   │
│  │  └───────────────┬────────────────────────┘  │   │
│  └──────────────────┼───────────────────────────┘   │
└─────────────────────┼───────────────────────────────┘
                      │ AES-256 encrypted
             ┌────────▼────────┐
             │  Wazuh Manager  │
             └────────┬────────┘
              ┌───────┴───────┐
         📧 Email       💬 Mattermost
```

> ⚠️ **Disclaimer:** The architecture diagram in `architecture/` was generated
> with an AI image tool and may contain inaccuracies. Always refer to this
> README and the configuration files for exact details.

---

## 🔄 Log Flow

| Step | Component | Action |
|------|-----------|--------|
| 1 | MikroTik routers | Send logs in **CEF format over TLS** → Graylog port **6514** |
| 2 | Graylog | Parses and stores logs in **OpenSearch** for visualization |
| 3 | Graylog Streams | Classifies logs by topic (FW, SYS, AUTH, INFO) |
| 4 | Graylog Syslog Output | Forwards to **rsyslog on localhost:514** (never exposed to network) |
| 5 | rsyslog | Writes to `/var/log/mikrotik.log` |
| 6 | Wazuh Agent | Reads file → forwards to **Wazuh Manager (AES-256)** |
| 7 | Wazuh Manager | Applies **custom decoders and rules** for threat detection |
| 8 | Active Response | **Email + Mattermost** on brute force detection |

---

## 📊 Graylog Streams

| Stream | Description |
|--------|-------------|
| `MikroTik Main Stream` | All MikroTik events |
| `MikroTik Firewall Events` | Events tagged `[FW]` |
| `MikroTik SYS-AUTH / LOGIN Events` | Authentication events |
| `MikroTik Login Info Stream` | `LOGGED IN` / `LOGGED OUT` events |
| `MikroTik Info Events (filtered)` | `[INFO]` filtered for `memory\|cpu` |
| `MikroTik SYS-SYSTEM Events` | `reboot\|config\|added\|removed` |

---

## 🗂️ Repository Structure

```
SIEM-MikroTik-Wazuh-Graylog/
│
├── README.md
├── architecture/
│   └── diagram.png
│
├── phase1-eve-ng/
│   ├── mikrotik/
│   │   └── cef-tls-config.md
│   ├── graylog/
│   │   ├── setup.md
│   │   └── screenshots/
│   ├── wazuh/
│   │   ├── decoders/
│   │   │   └── mikrotik-decoder.xml
│   │   ├── rules/
│   │   │   └── mikrotik-rules.xml
│   │   └── screenshots/
│   └── rsyslog/
│       └── graylog-wazuh.conf
│
├── phase2-production/
│   ├── wazuh/
│   │   ├── decoders/
│   │   │   └── mikrotik-decoder.xml   ← extended decoders
│   │   └── rules/
│   │       └── mikrotik-rules.xml     ← extended rules
│   └── screenshots/
│
└── docs/
    └── technical-report.pdf
```

---

## 🔄 Phase 2 — What Changed from Phase 1

> Full Phase 1 setup documentation remains valid.
> This section covers **only what was added or changed** in production.

### Router Identity
Phase 1 used numeric prefixes (`MKT[001]`–`MKT[006]`).
Phase 2 uses **real router hostnames** (e.g. `OFIR_MAIN_NEW`), requiring a new
parent decoder `mikrotik_graylog_identity` with a flexible PCRE2 regex.

### New Decoders
| Decoder | Detects |
|---------|---------|
| `mikrotik_graylog_identity` | Any real router name in `ROUTERNAME[TYPE]:` format |
| `mikrotik-reboot-conscious` | Reboot triggered by a user (who, from where, via what) |
| `mikrotik-reboot-unconscious` | Unexpected reboot with no user trigger |
| `mikrotik-reboot-cause` | System crash cause |
| `mikrotik-config-changed` | Config change (what, by whom, from where) |
| `mikrotik-resource-high` | CPU or RAM above threshold |
| `mikrotik-firewall` | Full firewall events (src/dst IP, ports, interfaces, action) |

### New Rules
| Rule ID | Level | Detects |
|---------|-------|---------|
| `110016` | 13 | Targeted brute force on a specific user |
| `100205` | 10 | Port scan (10+ events from same IP in 30s) |
| `100206` | 9 | External inbound traffic (non-RFC1918 source) |
| `100207` | 6 | Traffic via VPN interface `WG-Ofir` |
| `100204` | 7 | Access to web server `172.16.7.12` |
| `100400` | 8 | Conscious reboot |
| `100401` | 12 | Unexpected reboot |
| `100402` | 13 | Router crash cause |
| `100500` | 8 | CPU HIGH |
| `100501` | 8 | MEMORY HIGH |

---

## 🔑 Key Technical Discoveries

- **TLS requires `extendedKeyUsage=serverAuth`** — without it, RouterOS 7.23+ will not show TLS as available
- **`remote-protocol=tls` must be in the `add` command** — syntax error if set afterwards
- **Graylog output format must be `full`** — `plain` strips the `msg: MKT[...]` field
- **Localhost channel is secure by design** — TCP on `127.0.0.1` never leaves the machine
- **Two copies of logs, two purposes** — OpenSearch for visualization, Wazuh for detection
- **Active response script must use `timeout 3 cat`** — plain `cat` causes a deadlock
- **Real router names need a flexible parent decoder** — numeric IDs in Phase 1 don't scale to production hostnames

---

## ⚙️ Prerequisites

| Component | Version | Notes |
|-----------|---------|-------|
| MikroTik RouterOS | **7.23+** | Required for CEF over TLS |
| Ubuntu Server | 22.04 LTS | Hosts Graylog, rsyslog, Wazuh Agent |
| Graylog | 7.0 | + MongoDB + OpenSearch |
| Wazuh Manager | 4.x | Separate server |
| RAM (Graylog server) | 8 GB minimum | OpenSearch needs 4 GB heap |

---

## 🛠️ Troubleshooting

| Issue | Cause | Fix |
|-------|-------|-----|
| TLS not available in RouterOS | Missing `tls-server` in cert | Regenerate with `extendedKeyUsage=serverAuth` |
| `syntax error` on `remote-protocol=tls` | Used `set` instead of `add` | Delete action, recreate with `add` |
| No logs in `mikrotik.log` | Output not assigned to stream | Assign output to Default Stream |
| Logs in file but not in Wazuh | Wrong `localfile` path | Check `ossec.conf` localfile location |
| Decoder not matching | Wrong prematch or format | Use `wazuh-logtest` to debug |
| Active response not triggering | `cat` deadlock | Use `timeout 3 cat` |
| Real router name not decoded | Using old numeric decoder | Use `mikrotik_graylog_identity` parent |

---

## 👤 Author

**Mohamed Amine Namouchi**
Élève Ingénieur — Sécurité et Qualité des Réseaux, Polytech Dijon

[![LinkedIn](https://img.shields.io/badge/LinkedIn-namouchimohamedamine-blue?logo=linkedin)](https://linkedin.com/in/namouchimohamedamine)
[![GitHub](https://img.shields.io/badge/GitHub-MedNamouchi-black?logo=github)](https://github.com/MedNamouchi)

---

## 📄 License

MIT — feel free to use, adapt, and share with attribution.
