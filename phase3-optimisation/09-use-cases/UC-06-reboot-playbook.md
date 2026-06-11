# UC-06 — MikroTik Reboot Playbook

> **Task:** Transform MikroTik reboot rule into full use case  
> **Author:** Mohamed Amine Namouchi  
> **Date:** June 2026  
> **Status:** ✅ Complete

---

## Triggers

| Rule | Description | Level |
|------|-------------|-------|
| 100400 | Conscious reboot (triggered by user) | 8 |
| 100401 | Unexpected reboot (no user triggered) | 12 |
| 100402 | Router crash cause | 13 |

---

## Rule 100400 — Conscious Reboot (level 8)

### Identify
```
□ Who rebooted? (dstuser field)
□ Via which method? (winbox / ssh / api)
□ From which IP? (srcip field)
□ Which router? (router_name field)
□ Was it planned? (check UC-11 change windows)
```

### Validate
```
□ Is the user a known admin?
  grep "USER" /var/ossec/etc/lists/authorized-admin-ips

□ Was it during a maintenance window? (UC-11)

□ If YES to both → normal operation → log and close
□ If NO → suspicious → investigate
```

### Investigate (if suspicious)
```
□ Check what happened before the reboot:
  grep "router_name" /var/ossec/logs/alerts/alerts.log | tail -30

□ Check if preceded by brute force (100302):
  grep "100302" /var/ossec/logs/alerts/alerts.log | grep "SOURCE_IP"

□ Check if preceded by config change (100403):
  grep "100403" /var/ossec/logs/alerts/alerts.log | tail -10

□ Contact the user who rebooted — was it intentional?
```

### Close
```
□ Intentional → log in COM-05 as "Planned maintenance"
□ Suspicious → escalate to UC-04 (SOC Runbook)
```

---

## Rule 100401 — Unexpected Reboot (level 12)

### Identify
```
□ Which router rebooted? (router_name field)
□ What time? (timestamp)
□ Any recent alerts before reboot?
```

### Investigate
```
□ Check router logs for crash cause:
  MikroTik → Log → Filter by time of reboot

□ Check if rule 100402 (crash cause) fired:
  grep "100402" /var/ossec/logs/alerts/alerts.log | tail -5

□ Check power/hardware issues:
  MikroTik → System → Resources → check uptime history

□ Check if preceded by attack:
  grep "router_name" /var/ossec/logs/alerts/alerts.log | \
  grep "100302\|100403" | tail -10
```

### Contain
```
□ If hardware issue → notify Domagoj
□ If attack suspected → follow UC-01 (brute force) or UC-04
□ Monitor router closely for next 24h
```

### Close
```
□ Document in COM-05:
  - Router name
  - Time of reboot
  - Cause (power / hardware / attack / unknown)
  - Actions taken
```

---

## Rule 100402 — Router Crash Cause (level 13)

### Identify
```
□ Which router? (router_name)
□ What was the crash cause? (extra_data field)
   → kernel fault
   → power failure
   → watchdog timeout
   → software fault
```

### Investigate
```
□ kernel fault → possible software bug or attack
  → Check MikroTik firmware version
  → Check if update available: /system package update check-for-updates

□ power failure → hardware/electrical issue
  → Check UPS status
  → Notify Domagoj

□ watchdog timeout → router overload
  → Check CPU/RAM at time of crash
  → grep "100500\|100501" /var/ossec/logs/alerts/alerts.log | tail -10
```

### Remediation
```
□ kernel fault:
  MikroTik → System → Packages → Update firmware

□ power failure:
  → Check power supply + UPS

□ watchdog:
  → Review router load
  → Check for traffic spikes
```

### Close
```
□ Document in COM-05 with crash cause and actions
□ Monitor for recurrence
```

---

## Related Documents

| Document | Description |
|----------|-------------|
| UC-05 | Alert triage checklist |
| UC-04 | SOC Runbook |
| DET-06 | Rule testing samples (100400-100402) |
| COM-05 | Incident register |

---

*Document maintained as part of Phase 3 — Optimisation & Hardening*  
*Last updated: June 2026*
