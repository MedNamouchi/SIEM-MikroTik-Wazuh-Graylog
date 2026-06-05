# LOG-03 — Log Source Inventory

> **Task:** Create log source inventory document  
> **Author:** Mohamed Amine Namouchi  
> **Date:** June 3, 2026  
> **Status:** ✅ Complete

---

## Purpose

This document provides a complete inventory of all log sources
collected by the Wazuh SIEM at OFIR LTD.

It serves as the reference for:
- SOC analysts investigating incidents
- Compliance evidence (GDPR, CIS Controls)
- Onboarding new team members
- Troubleshooting pipeline issues

---

## Log Source Inventory

### Source 1 — MikroTik Routers

| Field | Value |
|-------|-------|
| **Source** | MikroTik CCR routers (6 devices) |
| **Owner** | Mohamed Amine Namouchi / Domagoj Muhar |
| **Collection Method** | CEF over TLS (port 6514) → Graylog → rsyslog → file → Wazuh Agent |
| **Format** | Syslog (converted from CEF by Graylog output plugin) |
| **File Path** | `/var/log/mikrotik.log` on Graylog server |
| **Agent** | graylog (agent 001) |
| **Retention** | 6 months |
| **Detection Value** | 🔴 Critical — brute force, auth, firewall, reboot, config change, CPU/RAM |
| **Rules** | 100200–100501 |
| **MITRE** | T1110, T1078, T1046, T1529, T1562 |

---

### Source 2 — Graylog Server — Auth & System

| Field | Value |
|-------|-------|
| **Source** | Graylog LXC Container — system logs |
| **Owner** | Mohamed Amine Namouchi / Domagoj Muhar |
| **Collection Method** | Wazuh Agent reads local files directly |
| **Format** | syslog |
| **File Path** | `/var/log/auth.log` + `/var/log/syslog` |
| **Agent** | graylog (agent 001) |
| **Retention** | 6 months |
| **Detection Value** | 🟠 High — SSH brute force, sudo abuse, unauthorized login on log pipeline server |
| **Rules** | Default Wazuh SSH rules (5700+) |
| **MITRE** | T1110, T1078 |

---

### Source 3 — Graylog Server — journald

| Field | Value |
|-------|-------|
| **Source** | Graylog LXC Container — systemd journal |
| **Owner** | Mohamed Amine Namouchi / Domagoj Muhar |
| **Collection Method** | Wazuh Agent reads journald directly |
| **Format** | journald |
| **Agent** | graylog (agent 001) |
| **Retention** | 6 months |
| **Detection Value** | 🟠 High — service starts/stops, system events |
| **Rules** | Default Wazuh systemd rules |

---

### Source 4 — Wazuh Manager — journald

| Field | Value |
|-------|-------|
| **Source** | Wazuh Manager server — systemd journal |
| **Owner** | Mohamed Amine Namouchi / Domagoj Muhar |
| **Collection Method** | Agent 000 (built-in local agent) reads journald |
| **Format** | journald |
| **Agent** | wazuh server (agent 000) |
| **Retention** | 6 months |
| **Detection Value** | 🔴 Critical — SSH access to security infrastructure |
| **Rules** | Default Wazuh SSH + PAM rules |
| **MITRE** | T1110, T1078 |
| **Note** | wazuh-agent cannot be installed on manager — use agent 000 |

---

### Source 5 — Wazuh Manager — System Logs

| Field | Value |
|-------|-------|
| **Source** | Wazuh Manager server — system logs |
| **Owner** | Mohamed Amine Namouchi / Domagoj Muhar |
| **Collection Method** | Agent 000 reads local files |
| **Format** | syslog |
| **File Path** | `/var/log/syslog` + `/var/log/dpkg.log` |
| **Agent** | wazuh server (agent 000) |
| **Retention** | 6 months |
| **Detection Value** | 🟠 High — system events, package installs on security server |

---

### Source 6 — Wazuh Active Response Logs

| Field | Value |
|-------|-------|
| **Source** | Active response execution logs |
| **Owner** | Mohamed Amine Namouchi / Domagoj Muhar |
| **Collection Method** | Agent reads local file |
| **Format** | syslog |
| **File Path** | `/var/ossec/logs/active-responses.log` |
| **Agent** | graylog (agent 001) + wazuh server (agent 000) |
| **Retention** | 6 months |
| **Detection Value** | 🟡 Medium — audit trail of all automated responses |

---

### Source 7 — punica.ofir.hr — System Logs (in progress) 

| Field | Value |
|-------|-------|
| **Source** | punica.ofir.hr server |
| **Owner** | Domagoj Muhar |
| **Collection Method** | Wazuh Agent (agent 002) |
| **Format** | journald + syslog |
| **Agent** | punica.ofir.hr (agent 002) |
| **Retention** | 6 months |
| **Detection Value** | 🟠 High — SSH brute force attempts detected in real time |
| **Note** | Active SSH scanning detected from external IPs |

---
### Source 8 — Graylog Application Logs

| Field | Value |
|-------|-------|
| **Source** | Graylog application — server.log |
| **Owner** | Mohamed Amine Namouchi / Domagoj Muhar |
| **Collection Method** | Wazuh Agent reads local file |
| **Format** | syslog |
| **File Path** | `/var/log/graylog-server/server.log` |
| **Agent** | graylog (agent 001) |
| **Retention** | 6 months |
| **Detection Value** | 🟠 High — pipeline failures, input errors, auth to Graylog UI |

## Pipeline Overview

```
MikroTik Routers (x6)
    → CEF over TLS port 6514
        ↓
Graylog 7.0
    → Converts CEF to Syslog
    → Forwards to rsyslog localhost:514
        ↓
rsyslog
    → Writes to /var/log/mikrotik.log
        ↓
Wazuh Agent 001 (graylog)
    → Reads mikrotik.log + auth.log + syslog + journald
    → Forwards AES-256 to Manager port 1514
        ↓
Wazuh Manager (agent 000)
    → Reads own journald + syslog
        ↓
Wazuh Manager — Analysis Engine
    → Decoders parse logs
    → Rules generate alerts
        ↓
Wazuh Indexer (OpenSearch)
    → Stores alerts and events
        ↓
Wazuh Dashboard
    → SOC visualization
```

---

## Retention Policy

| Source | Retention | Storage |
|--------|-----------|---------|
| All Wazuh alerts | 6 months | Wazuh Indexer (OpenSearch) |
| MikroTik raw logs | 6 months | /var/log/mikrotik.log (logrotate) |
| System logs | 6 months | journald + syslog (logrotate) |

---

## Coverage Map

```
✅ Network devices     → MikroTik routers (6)
✅ Log pipeline server → Graylog server
✅ SIEM server         → Wazuh Manager
✅ Other servers       → punica.ofir.hr

❌ Not yet covered:
→ Cloud services (if any)
→ Other network equipment (switches...)
→ Windows endpoints (if any)
```

---



*Document maintained as part of Phase 3 — Optimisation & Hardening*  
*Last updated: June 2026*
