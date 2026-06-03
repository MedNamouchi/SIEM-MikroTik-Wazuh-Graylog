# LOG-01 — Graylog Server System Log Collection

> **Task:** Deploy dedicated log collection on Graylog server  
> **Author:** Mohamed Amine Namouchi  
> **Date:** June 3, 2026  
> **Status:** ✅ Complete

---

## Context

The Wazuh agent running on the Graylog server was originally configured
to collect **only** MikroTik router logs from `/var/log/mikrotik.log`.

This left the Graylog server itself completely unmonitored — a critical
blind spot since this server hosts the entire log pipeline:

```
If the Graylog server is compromised:
→ Attacker can redirect or stop log forwarding
→ Wazuh receives no more MikroTik logs
→ No alerts generated
→ Attacker operates undetected
```

---

## What Was Added

Two new log sources added to the existing agent configuration:

| Source | Format | Security Value |
|--------|--------|---------------|
| `/var/log/auth.log` | syslog | SSH logins, sudo usage, PAM authentication events |
| `/var/log/syslog` | syslog | General system events, service starts/stops |

---

## Configuration

File: `/var/ossec/etc/ossec.conf` on the Graylog server

```xml
<!-- Graylog server system logs — Phase 3 LOG-01 -->
<localfile>
  <log_format>syslog</log_format>
  <location>/var/log/auth.log</location>
</localfile>

<localfile>
  <log_format>syslog</log_format>
  <location>/var/log/syslog</location>
</localfile>
```

Added after the existing `/var/log/mikrotik.log` localfile block.

---

## Validation

Confirmed working on 2026-06-03 — output from Wazuh manager alerts.log:

```
2026 Jun 03 09:37:31 (graylog) any->/var/log/auth.log
2026-06-03T09:37:29.836029+02:00 graylog su[339672]: pam_unix(su-l:session):
session opened for user root(uid=0) by root(uid=0)
```

Agent `graylog` reads `/var/log/auth.log` and forwards events
to the Wazuh manager in real time. ✅

---

## Detection Now Enabled

With auth.log collection active, the following threats are now detectable
on the Graylog server itself:

| Threat | MITRE | Detection |
|--------|-------|-----------|
| SSH brute force | T1110 | Multiple failed SSH logins |
| Sudo abuse | T1078 | Unexpected sudo usage |
| Unauthorized login | T1078 | Login from unknown source IP |
| Session hijacking | T1563 | Unexpected PAM session opened |

---

## Before vs After

```
BEFORE LOG-01:
Agent graylog monitors → /var/log/mikrotik.log only
Graylog server itself  → completely unmonitored ❌

AFTER LOG-01:
Agent graylog monitors → /var/log/mikrotik.log (MikroTik logs)
                      → /var/log/auth.log      (server auth) ✅
                      → /var/log/syslog        (server system) ✅
```

---

*Document maintained as part of Phase 3 — Optimisation & Hardening*  
*Last updated: June 2026*
