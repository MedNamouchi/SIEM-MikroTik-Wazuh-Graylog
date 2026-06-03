# FIM-12 — File Owners and Validation Responsibilities

> **Task:** FIM-12 — Document file owners for each monitored path  
> **Author:** Mohamed Amine Namouchi  
> **Date:** June 3, 2026  
> **Status:** ✅ Complete

---

## Purpose

When a FIM alert fires, the analyst must know **who to contact**
to validate whether the change was authorized.

This document maps each monitored path to its responsible owner.

---

## Ownership Table

| Path | System Role | Owner Role | Validates? | Escalate To |
|------|------------|-----------|-----------|-------------|
| `/var/ossec/etc/` | Wazuh config | Security Engineer | Yes | Security Lead |
| `/var/ossec/etc/decoders/` | Wazuh decoders | Security Engineer | Yes | Security Lead |
| `/var/ossec/etc/rules/` | Wazuh rules | Security Engineer | Yes | Security Lead |
| `/var/ossec/active-response/bin/` | AR scripts | Security Engineer | Yes | Security Lead |
| `/etc/graylog/` | Graylog config | Security Engineer | Yes | Security Lead |
| `/etc/rsyslog.conf` | rsyslog config | Security Engineer | Yes | Security Lead |
| `/etc/rsyslog.d/` | rsyslog drop-ins | Security Engineer | Yes | Security Lead |
| `/etc/passwd` | System accounts | System Administrator | Yes | Security Lead |
| `/etc/shadow` | Password hashes | System Administrator | Yes | Security Lead |
| `/etc/sudoers` | Sudo privileges | System Administrator | Yes | Security Lead |
| `/etc/ssh/sshd_config` | SSH config | System Administrator | Yes | Security Lead |
| `/etc/crontab` | Cron jobs | System Administrator | Yes | Security Lead |
| `/etc/cron.d/` | Cron drop-ins | System Administrator | Yes | Security Lead |
| `/var/log/auth.log` | Auth logs | Security Engineer | Yes | Security Lead |

---

## Validation Process

When a FIM alert fires:

```
1. Analyst receives Mattermost + email alert
        ↓
2. Analyst checks ownership table
        ↓
3. Analyst contacts the file owner
        ↓
4. Owner confirms:
   AUTHORIZED   → document as planned change, close alert
   UNAUTHORIZED → escalate immediately to Security Lead
```

---

## Transition Plan

> ⚠️ This document must be updated when team members change.
> Ownership should be reviewed at every team transition.

```
Current period  : SOC Analyst 1
Next period     : SOC Analyst 2
Action required : Update internal OFIR version with new owner details
```

---



*Document maintained as part of Phase 3 — Optimisation & Hardening*  
*Last updated: June 2026*
