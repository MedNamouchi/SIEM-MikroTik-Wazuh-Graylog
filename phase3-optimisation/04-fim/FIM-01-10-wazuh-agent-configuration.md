# FIM-01 to FIM-10 — File Integrity Monitoring Configuration

> **Tasks:** FIM-01, FIM-02, FIM-03, FIM-04, FIM-05, FIM-06, FIM-07, FIM-08, FIM-09, FIM-10  
> **Author:** Mohamed Amine Namouchi  
> **Date:** June 3, 2026  
> **Status:** ✅ Complete

---

## Context

File Integrity Monitoring (FIM) detects unauthorized modifications,
creations, and deletions of critical files.

Wazuh FIM works by computing a hash of each monitored file at baseline,
then comparing periodically — or in real time — to detect any change:

```
File monitored → hash computed at baseline
        ↓
File changes → new hash detected
        ↓
Alert generated with:
  - Which file changed
  - Old hash vs new hash
  - Owner, permissions, modification time
  - Who modified it (if process info available)
```

Before Phase 3, **no critical paths were explicitly monitored** beyond
the default Wazuh syscheck paths (`/etc`, `/bin`, `/sbin`...).

---

## Monitored Paths — Added in Phase 3

All paths use `check_all="yes" realtime="yes"` for full metadata
capture and inotify-based real-time detection.

### FIM-01 — Wazuh Main Configuration
| Path | Risk if modified |
|------|-----------------|
| `/var/ossec/etc` | If `ossec.conf` is modified silently, the entire detection platform can be disabled |

### FIM-02 — Wazuh Detection Logic
| Path | Risk if modified |
|------|-----------------|
| `/var/ossec/etc/decoders` | Modified decoders stop parsing logs → rules never match → zero alerts |
| `/var/ossec/etc/rules` | Modified rules stop detection → alerts stop firing silently |

### FIM-03 — Active Response Scripts
| Path | Risk if modified |
|------|-----------------|
| `/var/ossec/active-response/bin` | Tampered scripts → automated defenses behave unpredictably or stop working |

### FIM-04 — Graylog Configuration
| Path | Risk if modified |
|------|-----------------|
| `/etc/graylog` | Graylog output plugin config — if changed, log format changes → decoders break silently |

### FIM-05 — rsyslog Configuration
| Path | Risk if modified |
|------|-----------------|
| `/etc/rsyslog.conf` | If modified, MikroTik logs may stop arriving silently |
| `/etc/rsyslog.d` | Drop-in rsyslog configs — same risk |

### FIM-06 — System Accounts
| Path | Risk if modified |
|------|-----------------|
| `/etc/passwd` | Unauthorized user creation or account modification |
| `/etc/shadow` | Password hash tampering — credential theft indicator |
| `/etc/sudoers` | Privilege escalation — attacker grants sudo to compromised account |

### FIM-07 — SSH Configuration
| Path | Risk if modified |
|------|-----------------|
| `/etc/ssh/sshd_config` | Detect if SSH reconfigured to allow root login or password auth |

### FIM-08 — Scheduled Tasks (T1053)
| Path | Risk if modified |
|------|-----------------|
| `/etc/crontab` | Persistence via scheduled tasks — attacker schedules malicious job |
| `/etc/cron.d` | Drop-in cron jobs — same risk |

### FIM-09 — Auth Log Integrity (T1070)
| Path | Risk if modified |
|------|-----------------|
| `/var/log/auth.log` | Detect if auth logs are deleted or truncated — Defense Evasion |

### FIM-10 — Full Metadata Capture
Achieved via `check_all="yes"` on all monitored paths.

Captures:
- MD5 hash ✅
- SHA256 hash ✅
- File owner ✅
- Permissions ✅
- Modification time ✅
- Inode ✅

---

## Configuration Applied

File: `/var/ossec/etc/ossec.conf` on the Graylog server

```xml
<!-- Critical paths - Graylog server monitoring (Phase 3) -->

<!-- FIM-01: Wazuh main config -->
<directories check_all="yes" realtime="yes">/var/ossec/etc</directories>

<!-- FIM-02: Wazuh detection logic -->
<directories check_all="yes" realtime="yes">/var/ossec/etc/decoders</directories>
<directories check_all="yes" realtime="yes">/var/ossec/etc/rules</directories>

<!-- FIM-03: Active response scripts -->
<directories check_all="yes" realtime="yes">/var/ossec/active-response/bin</directories>

<!-- FIM-04: Graylog config -->
<directories check_all="yes" realtime="yes">/etc/graylog</directories>

<!-- FIM-05: rsyslog config -->
<directories check_all="yes" realtime="yes">/etc/rsyslog.conf</directories>
<directories check_all="yes" realtime="yes">/etc/rsyslog.d</directories>

<!-- FIM-06: System accounts -->
<directories check_all="yes" realtime="yes">/etc/passwd</directories>
<directories check_all="yes" realtime="yes">/etc/shadow</directories>
<directories check_all="yes" realtime="yes">/etc/sudoers</directories>

<!-- FIM-07: SSH config -->
<directories check_all="yes" realtime="yes">/etc/ssh/sshd_config</directories>

<!-- FIM-08: Scheduled tasks -->
<directories check_all="yes" realtime="yes">/etc/crontab</directories>
<directories check_all="yes" realtime="yes">/etc/cron.d</directories>

<!-- FIM-09: Auth log integrity -->
<directories check_all="yes" realtime="yes">/var/log/auth.log</directories>
```

---

## Validation

FIM tested on 2026-06-03 by modifying `/var/ossec/etc/ossec.conf`:

```bash
# Add test comment
echo "# test FIM" >> /var/ossec/etc/ossec.conf
# Alert generated on manager ✅
# Revert
sed -i '$ d' /var/ossec/etc/ossec.conf
```

FIM alert confirmed in Wazuh manager dashboard. ✅
---

*Document maintained as part of Phase 3 — Optimisation & Hardening*  
*Last updated: June 2026*
