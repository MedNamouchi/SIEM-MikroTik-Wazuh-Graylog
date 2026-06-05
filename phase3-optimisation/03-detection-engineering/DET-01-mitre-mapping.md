# DET-01 — MITRE ATT&CK Mapping

> **Task:** Add MITRE ATT&CK mapping to all existing rules  
> **Author:** Mohamed Amine Namouchi  
> **Date:** June 2026  
> **Status:** ✅ Complete

---

## What is MITRE ATT&CK

MITRE ATT&CK is a globally recognized knowledge base that catalogs
tactics and techniques used by real-world attackers.

Each technique has a unique ID (e.g. `T1110` for Brute Force).
Mapping Wazuh rules to MITRE provides:

```
→ Immediate context when an alert fires
→ Detection coverage measurement across 14 tactics
→ Standard language for SOC communication
→ Populated MITRE ATT&CK view in Wazuh Dashboard
```

---

## Rules Mapping — Complete Table

### Firewall Rules

| Rule ID | Description | MITRE Technique | Tactic |
|---------|-------------|----------------|--------|
| 100200 | Firewall event | T1071 | Command & Control |
| 100201 | Allowed connection | T1071 | Command & Control |
| 100202 | Blocked connection | T1071 | Command & Control |
| 100203 | Event on main router | T1071 | Command & Control |
| 100204 | Access to web server | T1190 | Initial Access |
| 100205 | Port scan detected | T1046 | Discovery |
| 100206 | External inbound traffic | T1071 | Command & Control |
| 100207 | Traffic via VPN interface | T1071 | Command & Control |

### Authentication Rules

| Rule ID | Description | MITRE Technique | Tactic |
|---------|-------------|----------------|--------|
| 100300 | Login success | T1078 | Defense Evasion / Persistence |
| 100301 | Login failure | T1110 | Credential Access |
| 100302 | Brute force (5+ failures) | T1110.001 | Credential Access |
| 100303 | Logout | T1078 | Defense Evasion / Persistence |
| 100304 | Login success after failures | T1110 | Credential Access |

### System Rules

| Rule ID | Description | MITRE Technique | Tactic |
|---------|-------------|----------------|--------|
| 100400 | Conscious reboot | T1529 | Impact |
| 100401 | Unexpected reboot | T1529 | Impact |
| 100402 | Router crash cause | T1529 | Impact |
| 100403 | Config change | T1562 | Defense Evasion |

### Resource Monitoring Rules

| Rule ID | Description | MITRE Technique | Tactic |
|---------|-------------|----------------|--------|
| 100500 | CPU HIGH | T1496 | Impact |
| 100501 | MEMORY HIGH | T1496 | Impact |

### Agent Monitoring Rules

| Rule ID | Description | MITRE Technique | Tactic |
|---------|-------------|----------------|--------|
| 100600 | Agent disconnected | T1562.001 | Defense Evasion |

---

## Detection Coverage Map

```
14 MITRE ATT&CK Tactics:

✅ Initial Access        → T1190 (web server access)
✅ Discovery             → T1046 (port scan)
✅ Credential Access     → T1110, T1110.001 (brute force)
✅ Defense Evasion       → T1562, T1562.001 (config change, agent down)
✅ Persistence           → T1078 (valid accounts)
✅ Command & Control     → T1071 (firewall events)
✅ Impact                → T1529 (reboot), T1496 (CPU/RAM)

❌ Execution             → needs endpoint agents
❌ Privilege Escalation  → needs endpoint agents
❌ Lateral Movement      → needs Windows logs / Suricata
❌ Collection            → needs DLP / file monitoring
❌ Exfiltration          → needs Zeek / Suricata
❌ Reconnaissance        → needs network monitoring
❌ Resource Development  → external threat intel needed
```

---

## Validation

Confirmed working with wazuh-logtest on 2026-06-05:

```
**Phase 3: Completed filtering (rules).
        id: '100301'
        mitre.id: '['T1110']'
        mitre.tactic: '['Credential Access']'
        mitre.technique: '['Brute Force']'
```

MITRE tags visible in Wazuh Dashboard MITRE ATT&CK view. ✅

---

*Document maintained as part of Phase 3 — Optimisation & Hardening*  
*Last updated: June 2026*
