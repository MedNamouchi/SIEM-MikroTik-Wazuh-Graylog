# INT-06 — SOC Integration Workflow

> **Task:** Document SOC integration workflow  
> **Author:** Mohamed Amine Namouchi  
> **Date:** June 2026  
> **Status:** ✅ Complete

---

## Overview

This document describes the end-to-end workflow of the OFIR SIEM —
from log collection to incident resolution.

---

## Architecture Overview

```
MikroTik Routers (6x CCR)
        ↓ CEF/TLS port 6514
Graylog 7.0 (GRAYLOG_IP)
        ↓ rsyslog → /var/log/mikrotik.log
Wazuh Agent 001 (on Graylog)
        ↓ AES-256 encrypted
Wazuh Manager (WAZUH_IP)
        ↓
OpenSearch → Dashboard
        ↓
Active Response → Mattermost + Email + iptables
```

---

## Alert Lifecycle

### Phase 1 — Detection

```
Wazuh analyzes incoming logs
→ Decoder extracts fields (srcip, router_name, dstuser...)
→ Rules match against decoded fields
→ Alert generated with level + MITRE + compliance tags
```

Key detection rules:
```
100302 → MikroTik brute force (level 10)
100800 → Coordinated attack MikroTik + SSH (level 15)
100401 → Unexpected router reboot (level 12)
100402 → Router crash cause (level 13)
100403 → Config change (level 5)
```

---

### Phase 2 — Notification

```
Alert level ≥ configured threshold
        ↓
Active Response script triggered
        ↓
Mattermost notification (enriched):
  → Geolocation of attacker IP
  → MITRE ATT&CK technique
  → Occurrences count
  → AR status (blocked or not)
  → Dashboard link

Email notification:
  → Full alert details
  → Recommended actions
  → Wazuh dashboard link
```

Scripts:
```
new_script_wazuh_mail_mattermost.sh → brute force
mattermost-correlation-alert.sh     → coordinated attack
mattermost-reboot-alert.sh          → reboot
mattermost-config-alert.sh          → config change
mattermost-resource-alert.sh        → CPU/RAM
mattermost-agent-down.sh            → agent disconnect
iptables-block.sh                   → auto IP block (10 min)
```

---

### Phase 3 — Triage

```
Analyst receives Mattermost notification
        ↓
Is this a real incident or false positive?

False positive indicators:
→ IP is in authorized-admin-ips whitelist
→ Known maintenance window
→ Scheduled task (WireGuard auto-update → rule 100404 suppresses)

Real incident indicators:
→ Unknown external IP
→ Multiple systems attacked
→ Outside business hours
→ Level 12+
```

---

### Phase 4 — Investigation

```
Open Wazuh Dashboard → https://WAZUH_IP
        ↓
Security Alerts → filter by srcip or rule_id
        ↓
Questions to answer:
→ When did the attack start?
→ How many attempts?
→ Did any login succeed? (check rule 100300)
→ Is the IP known malicious? (check VirusTotal)
→ Is the IP still active?
```

Tools available:
```
Wazuh Dashboard   → alert history + FIM + SCA
VirusTotal        → IP/hash reputation (INT-01)
MikroTik logs     → router-side verification
/var/log/auth.log → SSH login history on Graylog
```

---

### Phase 5 — Containment

```
Automatic (already done by AR):
→ iptables block for 10 minutes (iptables-block.sh)

Manual if needed:
→ Extend block: iptables -A INPUT -s IP -j DROP
→ Block on MikroTik: IP → Firewall → Add DROP rule
→ Unblock (rollback): iptables -D INPUT -s IP -j DROP
   See: AR-07-manual-rollback-procedure.md
```

---

### Phase 6 — Resolution & Documentation

```
1. Confirm threat is contained
2. Check for persistence:
   → /etc/passwd, /etc/shadow
   → /etc/crontab, /etc/cron.d/
   → ~/.ssh/authorized_keys
   → FIM alerts in dashboard

3. Document in incident register (COM-05):
   → Date + time
   → Alert type + rule ID
   → Source IP + geolocation
   → Actions taken
   → Resolution

4. Tune rules if false positive:
   → Add IP to whitelist if legitimate
   → Adjust rule threshold if too sensitive
```

---

## Escalation Matrix

| Level | Severity | Response Time | Action |
|-------|----------|--------------|--------|
| 3-5 | Low/Info | Next business day | Log and monitor |
| 8-10 | Medium/High | Same day | Investigate + contain |
| 12-13 | Critical | Within 1 hour | Immediate response |
| 15 | Maximum | Immediate | All hands + escalate |

---

## Key Contacts

> See OFIR Internal documentation for contact details.

---

## Related Documents

| Document | Description |
|----------|-------------|
| AR-07 | Manual IP unblock procedure |
| DET-06 | Rule testing samples |
| DET-07 | Multi-source correlation |
| FIM-11 | FIM use case playbook |
| UC-01 to UC-11 | Specific incident playbooks (TODO) |

---

*Document maintained as part of Phase 3 — Optimisation & Hardening*  
*Last updated: June 2026*
