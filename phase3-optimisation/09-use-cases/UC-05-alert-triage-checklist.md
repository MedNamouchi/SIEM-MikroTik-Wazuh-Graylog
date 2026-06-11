# UC-05 — Alert Triage Checklist

> **Task:** Create alert triage checklist  
> **Author:** Mohamed Amine Namouchi  
> **Date:** June 2026  
> **Status:** ✅ Complete

---

## Purpose

A standardized checklist to follow for every incoming Wazuh alert.
Goal: decide within 2 minutes if the alert is a real incident or a false positive.

---

## Step 1 — Read the Alert (30 seconds)

```
□ What is the rule ID?
□ What is the severity level?
□ What is the source IP?
□ What is the affected system (router / Graylog / Wazuh)?
□ What time did it happen?
```

---

## Step 2 — Quick Severity Check (10 seconds)

| Level | Action |
|-------|--------|
| 3-5 | Log and monitor — no immediate action |
| 8-10 | Investigate within the day |
| 12-13 | Investigate within 1 hour |
| 15 | Immediate response — drop everything |

---

## Step 3 — False Positive Check (30 seconds)

```
□ Is the source IP in the whitelist?
   → /var/ossec/etc/lists/authorized-admin-ips
   → If YES → likely false positive → log and close

□ Is it a known scheduled task?
   → WireGuard auto-update → rule 100404 suppresses it
   → Scheduled maintenance → check UC-11 change windows

□ Is it a test or lab activity?
   → Internal IPs (172.30.x.x, 10.10.x.x) during business hours
   → If YES → log as test activity → close
```

---

## Step 4 — Context Check (30 seconds)

```
□ Has this IP triggered alerts before?
   grep "SOURCE_IP" /var/ossec/logs/alerts/alerts.log | wc -l

□ Is the IP external or internal?
   → External → higher priority
   → Internal → check who owns the IP

□ Check geolocation in Mattermost notification
   → Country / Organization of the IP

□ Check VirusTotal result if available
   → Malicious → critical priority
```

---

## Step 5 — Decision

```
FALSE POSITIVE:
□ Log in incident register (COM-05) as "False Positive"
□ Add IP to whitelist if legitimate
□ Close

REAL INCIDENT:
□ Log in incident register (COM-05) as "Open"
□ Follow the appropriate playbook:
   → Brute Force    → UC-01
   → Reboot         → UC-06
   → Config Change  → UC-07
   → Resource Alert → UC-08
   → Log Clearing   → UC-02
   → Coordinated    → UC-04 (SOC Runbook)
```

---

## Quick Reference Commands

```bash
# Check alert history for an IP
grep "SOURCE_IP" /var/ossec/logs/alerts/alerts.log | tail -20

# Check if IP is whitelisted
grep "SOURCE_IP" /var/ossec/etc/lists/authorized-admin-ips

# Check if IP is currently blocked
iptables -L INPUT -n | grep "SOURCE_IP"

# Check auth log for successful login
grep "SOURCE_IP" /var/log/auth.log | grep "Accepted"

# Unblock an IP (rollback)
iptables -D INPUT -s SOURCE_IP -j DROP
```

---

## Alert Types Quick Reference

| Rule | Type | Level | Default Action |
|------|------|-------|---------------|
| 100302 | MikroTik Brute Force | 10 | Investigate + check if login succeeded |
| 100401 | Unexpected Reboot | 12 | Check router + investigate cause |
| 100402 | Router Crash | 13 | Immediate investigation |
| 100403 | Config Change | 5 | Verify who changed what |
| 100500/501 | CPU/RAM High | 8 | Check router load |
| 100600/601 | Agent Down | 10/12 | Check server + pipeline |
| 100800/801 | Coordinated Attack | 15 | Immediate full response |
| 87105 | VirusTotal Malware | 12 | Isolate + investigate |

---

*Document maintained as part of Phase 3 — Optimisation & Hardening*  
*Last updated: June 2026*
