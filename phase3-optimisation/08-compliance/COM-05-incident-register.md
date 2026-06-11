# COM-05 — Incident Register

> **Task:** Start an incident register  
> **Author:** Mohamed Amine Namouchi  
> **Date:** June 2026  
> **Status:** ✅ Complete

---

## Context

An incident register provides a structured record of all security
incidents — required by GDPR Article 33 for breach notification
and by CIS Controls for continuous improvement.

---

## Register Location

The live incident register is maintained in a shared Google Sheet
accessible to the security team.

```
Columns:
Date | Incident ID | Type | Rule ID | Source IP | Country |
Severity | Description | Actions Taken | Resolved By | Status | Notes
```

---

## Incident Types

```
Brute Force       → Rule 100302 (MikroTik) / 5712 (SSH)
Coordinated Attack → Rules 100800/100801
Config Change     → Rule 100403
Unexpected Reboot → Rule 100401
Crash             → Rule 100402
Resource Alert    → Rules 100500/100501
Agent Down        → Rules 100600/100601
FIM Alert         → Wazuh FIM rules
Vulnerability     → Wazuh Vulnerability Detection
```

---

## Severity Scale

| Level | Severity | Response Time |
|-------|----------|--------------|
| 3-5 | Low | Next business day |
| 8-10 | Medium/High | Same day |
| 12-13 | Critical | Within 1 hour |
| 15 | Maximum | Immediate |

---

## Sample Entry

| Field | Example |
|-------|---------|
| Date | 2026-06-10 |
| Incident ID | INC-001 |
| Type | Brute Force |
| Rule ID | 100302 |
| Source IP | Anonymized |
| Country | Internal |
| Severity | 10 |
| Description | 5+ login failures on main router via winbox |
| Actions Taken | IP auto-blocked 10min by iptables |
| Resolved By | Security team |
| Status | Closed |

---


*Document maintained as part of Phase 3 — Optimisation & Hardening*  
*Last updated: June 2026*
