# UC-08 — Resource Monitoring Playbook

> **Task:** Create resource monitoring use case  
> **Author:** Mohamed Amine Namouchi  
> **Date:** June 2026  
> **Status:** ✅ Complete

---

## Triggers

| Rule | Description | Level |
|------|-------------|-------|
| 100500 | CPU HIGH on MikroTik router | 8 |
| 100501 | MEMORY HIGH on MikroTik router | 8 |

---

## Phase 1 — Identify

```
□ Which router? (router_name field)
□ Which resource? CPU or MEMORY (resource_type field)
□ What value? (resource_value field — percentage)
□ What time?
□ Is it still ongoing?
  tail -f /var/ossec/logs/alerts/alerts.log | grep "100500\|100501"
```

---

## Phase 2 — Validate

```
□ Is it a one-time spike or sustained?
  grep "100500\|100501" /var/ossec/logs/alerts/alerts.log | \
  grep "router_name" | tail -20

□ One-time spike → likely normal traffic burst → monitor
□ Sustained high → investigate immediately
```

---

## Phase 3 — Investigate

### On MikroTik router
```
MikroTik → Tools → Profile
→ What process is consuming CPU?

MikroTik → System → Resources
→ Current CPU + memory usage
→ Uptime

MikroTik → Tools → Torch
→ What traffic is passing through?
→ Any unusual traffic volume?

MikroTik → IP → Firewall → Connections
→ How many active connections?
→ Any suspicious IPs?
```

### Check for attack-related causes
```bash
# Port scan or DDoS?
grep "100205" /var/ossec/logs/alerts/alerts.log | tail -10

# Brute force generating load?
grep "100302" /var/ossec/logs/alerts/alerts.log | tail -10

# External traffic spike?
grep "100206" /var/ossec/logs/alerts/alerts.log | tail -10
```

### Common causes
```
CPU HIGH :
→ DDoS attack → many connections
→ Port scan → many SYN packets
→ Routing loop → CPU processing loop
→ Firmware bug → software issue
→ Traffic spike → legitimate peak

MEMORY HIGH :
→ Too many active connections
→ Large routing table
→ Memory leak in firmware
→ DDoS → connection table full
```

---

## Phase 4 — Contain

### If attack-related
```
□ Identify and block attacking IP:
  iptables -A INPUT -s SOURCE_IP -j DROP
  MikroTik → IP → Firewall → Add DROP rule

□ Enable connection limiting on MikroTik:
  MikroTik → IP → Firewall → Filter Rules
  → Add rule: limit connections per IP

□ Follow UC-01 if brute force detected
```

### If legitimate traffic spike
```
□ Monitor — no action needed
□ Notify Domagoj if sustained
□ Consider bandwidth upgrade if recurrent
```

### If firmware/software issue
```
□ Check for firmware update:
  MikroTik → System → Packages → Check for updates

□ Reboot router if safe to do so:
  MikroTik → System → Reboot
  (This will trigger rule 100400 — normal)
```

---

## Phase 5 — Close

```
□ Confirm resource usage back to normal:
  MikroTik → System → Resources

□ Document in COM-05:
  - Router name
  - Resource type (CPU/MEMORY)
  - Peak value
  - Duration
  - Root cause
  - Actions taken

□ Monitor for recurrence over next 24h
```

---

## Thresholds Reference

```
Current alert threshold : any WARN from MikroTik script
Recommended thresholds :
  CPU    > 80% sustained → investigate
  MEMORY > 85% sustained → investigate
```

---

## Related Documents

| Document | Description |
|----------|-------------|
| UC-05 | Alert triage checklist |
| UC-01 | Brute force playbook (if attack-related) |
| DET-06 | Rule testing samples (100500/100501) |
| COM-05 | Incident register |

---

*Document maintained as part of Phase 3 — Optimisation & Hardening*  
*Last updated: June 2026*
