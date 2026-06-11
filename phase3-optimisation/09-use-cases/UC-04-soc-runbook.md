# UC-04 — SOC Runbook (NIST IR Framework)

> **Task:** Write complete SOC runbook  
> **Author:** Mohamed Amine Namouchi  
> **Date:** June 2026  
> **Status:** ✅ Complete

---

## Overview

This runbook defines the end-to-end incident response process
at OFIR LTD, based on the NIST SP 800-61 framework.

```
Preparation → Detection → Containment → Eradication → Recovery → Post-Incident
```

---

## Phase 1 — Preparation

**Goal:** Ensure all tools and processes are ready before an incident occurs.

```
□ Wazuh Manager running:
  systemctl status wazuh-manager

□ Wazuh agents connected:
  /var/ossec/bin/agent_control -l

□ Mattermost notifications working:
  Check last alert in #sto-jedemo channel

□ iptables-block.sh deployed and tested:
  ls -la /var/ossec/active-response/bin/iptables-block.sh

□ Whitelist up to date:
  cat /var/ossec/etc/lists/authorized-admin-ips

□ SSH keys working (PuTTY → Graylog + Wazuh):
  Test connection before incident

□ Incident register ready (COM-05):
  Google Sheet open and accessible
```

---

## Phase 2 — Detection

**Goal:** Identify and confirm a security incident.

```
□ Receive alert on Mattermost
□ Read alert details:
  - Rule ID + level
  - Source IP + geolocation
  - Affected system
  - MITRE ATT&CK technique

□ Run triage checklist (UC-05)
□ Open Wazuh Dashboard:
  https://WAZUH_IP → Security Alerts

□ Search for related events:
  grep "SOURCE_IP" /var/ossec/logs/alerts/alerts.log | tail -30

□ Confirm: Real incident or false positive?
```

**Severity thresholds:**
```
Level 3-5  → Monitor only
Level 8-10 → Investigate same day
Level 12-13 → Investigate within 1 hour
Level 15   → Immediate response
```

---

## Phase 3 — Containment

**Goal:** Stop the attack from spreading.

### Short-term containment (immediate)
```
□ Verify auto-block status:
  iptables -L INPUT -n | grep "SOURCE_IP"

□ Extend block if needed:
  iptables -A INPUT -s SOURCE_IP -j DROP

□ Block on MikroTik routers:
  MikroTik → IP → Firewall → Add DROP rule for SOURCE_IP

□ If login succeeded → change passwords immediately:
  MikroTik → /ip user → change password for all admin users
```

### Long-term containment
```
□ Add IP to permanent blacklist
□ Review firewall rules on all routers
□ Restrict access to trusted IPs only
□ Enable additional logging if needed
```

---

## Phase 4 — Eradication

**Goal:** Remove the threat completely.

```
□ Check for persistence on MikroTik:
  /ip user print          → unauthorized users?
  /system scheduler print → unauthorized tasks?
  /system script print    → malicious scripts?
  /ip firewall filter print → unauthorized rules?

□ Check for persistence on Graylog server:
  cat /etc/passwd         → new users?
  cat /etc/crontab        → scheduled tasks?
  cat /etc/cron.d/*       → cron jobs?
  cat ~/.ssh/authorized_keys → new SSH keys?

□ Check for persistence on Wazuh Manager:
  Same checks as Graylog

□ Check FIM alerts for modified files:
  Wazuh Dashboard → FIM → filter by date of incident

□ Verify VirusTotal results for any new files
```

---

## Phase 5 — Recovery

**Goal:** Restore normal operations safely.

```
□ Confirm attacker is no longer active:
  tail -f /var/ossec/logs/alerts/alerts.log | grep "SOURCE_IP"

□ Verify all services running normally:
  systemctl status wazuh-manager
  systemctl status wazuh-agent   (on Graylog)
  systemctl status graylog-server

□ Verify log pipeline is working:
  tail -f /var/log/mikrotik.log

□ Verify MikroTik logs still forwarding:
  Wazuh Dashboard → check recent MikroTik alerts

□ Remove temporary blocks if false positive:
  iptables -D INPUT -s SOURCE_IP -j DROP
  (See AR-07 for rollback procedure)

□ Resume normal monitoring
```

---

## Phase 6 — Post-Incident

**Goal:** Learn from the incident and improve defenses.

```
□ Document in incident register (COM-05):
  - Date + time
  - Incident ID
  - Type + rule ID
  - Source IP + country
  - Timeline of events
  - Actions taken
  - Resolution

□ Lessons learned:
  - Was detection fast enough?
  - Were notifications clear?
  - Was containment effective?
  - Any gaps in detection?

□ Tune rules if needed:
  - False positive → add to whitelist
  - Missed detection → adjust rule threshold

□ Update playbooks if needed
□ Share findings with Domagoj
```

---

## Escalation Matrix

| Situation | Action |
|-----------|--------|
| Level 10 alert | Mattermost notification → investigate |
| Level 13+ alert | Immediate investigation + notify Domagoj |
| Level 15 alert | Emergency response + phone call |
| Login succeeded after BF | Escalate immediately to Domagoj |
| Multiple systems attacked | Coordinated response + Domagoj |
| Pipeline down (agent disconnected) | Immediate investigation |

---

## Emergency Contacts

> See OFIR Internal documentation for contact details.

---

## Key Commands Reference

```bash
# Check agent status
/var/ossec/bin/agent_control -l

# Search alerts by IP
grep "SOURCE_IP" /var/ossec/logs/alerts/alerts.log | tail -30

# Block IP
iptables -A INPUT -s SOURCE_IP -j DROP

# Unblock IP
iptables -D INPUT -s SOURCE_IP -j DROP

# Check blocked IPs
iptables -L INPUT -n | grep DROP

# Add to whitelist
echo "IP:description" >> /var/ossec/etc/lists/authorized-admin-ips

# Restart Wazuh Manager
systemctl restart wazuh-manager

# Check pipeline
tail -f /var/log/mikrotik.log
```

---

*Document maintained as part of Phase 3 — Optimisation & Hardening*  
*Last updated: June 2026*
