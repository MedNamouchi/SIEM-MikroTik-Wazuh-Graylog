# COM-07 — Security Controls in Place

> **Task:** Document security controls in place  
> **Author:** Mohamed Amine Namouchi  
> **Date:** June 2026  
> **Status:** ✅ Complete

---

## Purpose

This document provides evidence that OFIR LTD has implemented
continuous security monitoring and appropriate technical measures
as required by GDPR Article 32 and CIS Controls.

---

## Log Collection & Pipeline

| Control | Description | Status | Evidence |
|---------|-------------|--------|---------|
| MikroTik log forwarding | 6 CCR routers → Graylog via CEF/TLS port 6514 | ✅ Active | LOG-01 |
| Graylog agent | Wazuh agent on Graylog server — collects auth + SSH + app logs | ✅ Active | LOG-01 |
| Wazuh Manager logs | SIEM monitors itself | ✅ Active | LOG-02 |
| Log source inventory | All sources documented with owner + format + retention | ✅ Active | LOG-03 |
| Graylog application logs | Graylog startup + stream errors collected | ✅ Active | LOG-04 |
| Log retention | 6 months via logrotate on all sources | ✅ Active | LOG-06 |
| Agent health monitoring | Alert when agent disconnects > 15 minutes | ✅ Active | LOG-07 |

---

## Detection Engineering

| Control | Description | Status | Evidence |
|---------|-------------|--------|---------|
| Custom decoders | 10 MikroTik decoders (auth, reboot, config, firewall, resources) | ✅ Active | DET-08 |
| Firewall monitoring | Rules 100200-100207 — block, external traffic, VPN | ✅ Active | DET-06 |
| Brute force detection | Rule 100302 — 5+ failures in 60s → level 10 | ✅ Active | DET-06 |
| Password spraying | Rule 100700 — same user, multiple IPs → level 12 | ✅ Active | DET-04 |
| Distributed attack | Rule 100701 — 10+ failures multiple IPs/users → level 14 | ✅ Active | DET-04 |
| Reboot detection | Rules 100400-100402 — conscious/unexpected/crash | ✅ Active | DET-06 |
| Config change detection | Rule 100403 — any config change on routers | ✅ Active | DET-06 |
| Resource monitoring | Rules 100500-100501 — CPU/RAM high | ✅ Active | DET-06 |
| Multi-source correlation | Rules 100800-100801 — MikroTik BF + SSH BF same IP → level 15 | ✅ Active | DET-07 |
| MITRE ATT&CK mapping | All 21 custom rules mapped to MITRE techniques | ✅ Active | DET-01 |
| Compliance tags | GDPR + NIST 800-53 + PCI-DSS tags on all rules | ✅ Active | DET-02 |
| IP whitelist (CDB) | Authorized admin IPs never blocked | ✅ Active | DET-03 |
| Rule testing | All rules validated with wazuh-logtest + sample logs | ✅ Active | DET-06 |

---

## File Integrity Monitoring

| Control | Description | Status | Evidence |
|---------|-------------|--------|---------|
| FIM — Wazuh config | /var/ossec/etc/ monitored realtime | ✅ Active | FIM-01 |
| FIM — Decoders/Rules | /var/ossec/etc/decoders/ + /rules/ monitored | ✅ Active | FIM-02 |
| FIM — AR scripts | /var/ossec/active-response/bin/ monitored | ✅ Active | FIM-03 |
| FIM — Graylog config | /etc/graylog/ monitored | ✅ Active | FIM-04 |
| FIM — rsyslog | /etc/rsyslog.conf + /etc/rsyslog.d/ monitored | ✅ Active | FIM-05 |
| FIM — User accounts | /etc/passwd + /etc/shadow + /etc/sudoers monitored | ✅ Active | FIM-06 |
| FIM — SSH config | /etc/ssh/sshd_config monitored | ✅ Active | FIM-07 |
| FIM — Cron jobs | /etc/crontab + /etc/cron.d/ monitored | ✅ Active | FIM-08 |
| FIM — Auth logs | /var/log/auth.log monitored | ✅ Active | FIM-09 |
| FIM metadata | check_all=yes — hash MD5+SHA256 + owner + permissions | ✅ Active | FIM-10 |

---

## Active Response & Hardening

| Control | Description | Status | Evidence |
|---------|-------------|--------|---------|
| Mattermost notifications | Real-time enriched alerts (geo + MITRE + AR status) | ✅ Active | INT-02 |
| Email notifications | Full alert details to security team | ✅ Active | AR-01 |
| Auto IP blocking | iptables block 10 minutes on brute force detection | ✅ Active | AR-05 |
| IP whitelist | Admin IPs never auto-blocked | ✅ Active | AR-01 |
| Manual rollback | Documented procedure to unblock IP immediately | ✅ Active | AR-07 |
| SSH hardening | Key-only auth + PermitRootLogin prohibit-password | ✅ Active | SCA-03 |
| SCA benchmark | CIS Debian 13 benchmark running on both servers | ✅ Active | SCA-02 |
| Vulnerability detection | Wazuh auto CVE scan on all agents | ✅ Active | SCA-01 |
| CVE remediation SLAs | Critical 48h / High 7d / Medium 30d / Low next cycle | ✅ Defined | DET-10 |

---

## Integrations

| Control | Description | Status | Evidence |
|---------|-------------|--------|---------|
| VirusTotal | Auto hash lookup on FIM new file detection | ✅ Active | INT-01 |
| Component health | monitor.ofir.hr — Wazuh + Graylog uptime monitoring | ✅ Active | INF-06 |
| Config backup | Proxmox backup of all SIEM servers | ✅ Active | INF-07 |

---

## Summary

```
Total controls implemented : 35
Active                     : 35 ✅
Pending                    : 0
```

---

## Compliance Coverage

| Framework | Coverage |
|-----------|---------|
| GDPR Article 32 | Log collection + monitoring + incident response + access control |
| NIST 800-53 | AC.7 + AU.12 + CM.6 + SI.4 + AU.14 |
| PCI-DSS | 10.2.4 + 10.2.5 + 10.2.6 + 10.6.1 + 11.4 |
| CIS Controls | 1 (inventory) + 6 (access) + 7 (vuln mgmt) + 8 (audit logs) + 13 (monitoring) |

---

*Document maintained as part of Phase 3 — Optimisation & Hardening*  
*Last updated: June 2026*
