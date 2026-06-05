# LOG-06 — Log Retention Policy

> **Task:** Define per-source retention policy  
> **Author:** Mohamed Amine Namouchi  
> **Date:** June 2026  
> **Status:** ✅ Complete

---

## Decision

All log sources retain data for **6 months**.

---

## Per-Source Retention Table

| Source | File/Location | Retention | Storage |
|--------|--------------|-----------|---------|
| MikroTik router logs | `/var/log/mikrotik.log` | 6 months | Logrotate maxage 180 |
| Graylog application logs | `/var/log/graylog-server/server.log` | 6 months | Logrotate monthly rotate 6 |
| Graylog syslog | `/var/log/syslog` | 6 months | Logrotate monthly rotate 6 |
| Graylog auth logs | `/var/log/auth.log` | 6 months | Logrotate monthly rotate 6 |
| Wazuh active-responses | `/var/ossec/logs/active-responses.log` | 6 months | Logrotate monthly rotate 6 |
| Wazuh ossec.log | `/var/ossec/logs/ossec.log` | 6 months | Logrotate monthly rotate 6 |
| Wazuh Manager syslog | `/var/log/syslog` | 6 months | Logrotate monthly rotate 6 |
| Wazuh Manager dpkg | `/var/log/dpkg.log` | 6 months | Logrotate monthly rotate 6 |
| Wazuh alerts/archives | `/var/ossec/logs/alerts/` | 6 months | Managed by Wazuh internally |
| All indexed alerts | Wazuh Indexer (OpenSearch) | 6 months | OpenSearch index lifecycle |

---

## Logrotate Configuration — Verified on 2026-06-05

### Graylog Server

**File:** `/etc/logrotate.d/mylogs`
```
/var/log/mikrotik.log {
    size 500M
    rotate 9999
    maxage 180
    compress
    missingok
    notifempty
    copytruncate
    dateext
}
```

**File:** `/etc/logrotate.d/graylog-server`
```
/var/log/graylog-server/console.log {
    monthly
    rotate 6
    compress
    delaycompress
    missingok
    notifempty
    copytruncate
}
```

**File:** `/etc/logrotate.d/rsyslog`
```
/var/log/syslog
/var/log/auth.log
/var/log/cron.log ... {
    monthly
    rotate 6
    compress
    delaycompress
    missingok
    notifempty
}
```

### Wazuh Manager Server

**File:** `/etc/logrotate.d/wazuh` *(created in Phase 3)*
```
/var/ossec/logs/active-responses.log
/var/ossec/logs/ossec.log {
    monthly
    rotate 6
    compress
    delaycompress
    missingok
    notifempty
    copytruncate
    dateext
    su root wazuh
}

/var/log/syslog
/var/log/dpkg.log {
    monthly
    rotate 6
    compress
    delaycompress
    missingok
    notifempty
    copytruncate
}
```

> ⚠️ Note: `/var/ossec/logs/alerts/` and `/var/ossec/logs/archives/`
> have hard links — they are managed by Wazuh internally,
> not by logrotate.

---

## Storage Estimation

Measured on 2026-06-05 (~7 weeks of data):

| Source | Current Size | Estimated 6 months |
|--------|-------------|-------------------|
| `/var/log/mikrotik.log` | 312MB | ~1.3GB raw / ~260MB compressed |
| `/var/log/graylog-server/` | 10MB | ~43MB |
| `/var/ossec/logs/` | 81MB | ~350MB |
| **Total** | **~403MB** | **~1.7GB raw / ~350MB compressed** |

Storage is not a concern — total estimated at ~350MB compressed over 6 months.

---

## Justification

```
GDPR requirement → minimum duration for incident investigation
CIS Controls     → recommend 90 days minimum
OFIR decision    → 6 months = adequate for investigation
                   + reasonable storage cost (~350MB compressed)
```

---

## Legal Hold

If an incident requires preserving logs beyond 6 months:

```
Action  : Manually backup relevant OpenSearch index
          before retention period expires
Storage : Secure internal location
```

---

## Review Schedule

| Review | Date | Responsible |
|--------|------|-------------|
| Initial definition | June 2026 | Security Team |
| First review | September 2026 | Security Lead |
| Annual review | June 2027 | Security Lead |

---

*Document maintained as part of Phase 3 — Optimisation & Hardening*  
*Last updated: June 2026*
