# UC-07 — MikroTik Config Change Playbook

> **Task:** Transform MikroTik config change rule into full use case  
> **Author:** Mohamed Amine Namouchi  
> **Date:** June 2026  
> **Status:** ✅ Complete

---

## Trigger

| Rule | Description | Level |
|------|-------------|-------|
| 100403 | Config changed on router | 5 |
| 100404 | WireGuard scheduler update (suppressed) | 0 |

---

## Phase 1 — Identify

```
□ Who made the change? (dstuser field)
□ Via which method? (access_method: winbox / ssh / api / scheduler)
□ What was changed? (change_type field)
   → ip/firewall/filter
   → ip/address
   → interface
   → system/scheduler
   → ip/route
□ What action? (extra_data: added / removed / modified)
□ Which router? (router_name field)
□ From which IP? (srcip field)
```

---

## Phase 2 — Validate

```
□ Is the user a known admin?
  grep "USER" /var/ossec/etc/lists/authorized-admin-ips

□ Was it during a maintenance window? (UC-11)

□ Was it the WireGuard scheduler? → rule 100404 suppresses it → ignore

□ If known admin + planned change → log and close ✅
□ If unknown user / unexpected change → investigate 🔴
```

---

## Phase 3 — Investigate

### Check what was changed
```bash
# Check recent config change alerts
grep "100403" /var/ossec/logs/alerts/alerts.log | tail -10

# Check if preceded by brute force
grep "100302" /var/ossec/logs/alerts/alerts.log | \
  grep "SOURCE_IP" | tail -5

# Check if preceded by successful login
grep "100300" /var/ossec/logs/alerts/alerts.log | \
  grep "SOURCE_IP" | tail -5
```

### Check on MikroTik directly
```
MikroTik → Log → Filter by topics: system
→ Look for entries around the time of alert

MikroTik → IP → Firewall → Filter Rules
→ Any suspicious new rules?

MikroTik → IP → Firewall → NAT
→ Any suspicious redirections?

MikroTik → System → Scheduler
→ Any suspicious scheduled tasks?

MikroTik → IP → Routes
→ Any suspicious new routes?
```

### High risk changes to investigate immediately
```
⚠️ ip/firewall/filter → new rule allowing traffic
⚠️ ip/firewall/nat   → new port forwarding / redirection
⚠️ system/scheduler  → new scheduled task
⚠️ ip/route          → new route (possible traffic hijack)
⚠️ system/user       → new admin user
⚠️ interface         → interface disabled (DoS attempt)
```

---

## Phase 4 — Contain

### If change is unauthorized
```
□ Revert the change immediately on MikroTik:
  → Find the change in the relevant section
  → Remove or revert to previous value

□ Block the source IP:
  iptables -A INPUT -s SOURCE_IP -j DROP
  MikroTik → IP → Firewall → Add DROP rule

□ Change admin passwords on all routers:
  MikroTik → /ip user → set password

□ Revoke access if compromised account:
  MikroTik → /ip user → disable or remove user
```

### If change is authorized but undocumented
```
□ Contact the admin who made the change
□ Document the reason for the change
□ Add to change log
```

---

## Phase 5 — Close

```
□ Verify router config is back to expected state
□ Verify no other unauthorized changes were made
□ Document in COM-05:
  - Router name
  - Change type
  - Who made it
  - Was it authorized?
  - Actions taken
  - Status: Closed

□ If unauthorized → also follow UC-04 (SOC Runbook)
   for full incident response
```

---

## Common False Positives

```
100404 → WireGuard auto-update by scheduler → suppressed ✅
Known admin making changes → verify and close
Scheduled backup scripts → add to whitelist
```

---

## Related Documents

| Document | Description |
|----------|-------------|
| UC-05 | Alert triage checklist |
| UC-01 | Brute force playbook (if preceded by BF) |
| UC-04 | SOC Runbook (full incident response) |
| DET-06 | Rule testing samples (100403/100404) |
| AR-07 | Manual rollback procedure |
| COM-05 | Incident register |

---

*Document maintained as part of Phase 3 — Optimisation & Hardening*  
*Last updated: June 2026*
