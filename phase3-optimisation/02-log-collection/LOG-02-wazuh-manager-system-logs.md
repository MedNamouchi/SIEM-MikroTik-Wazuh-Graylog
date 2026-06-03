# LOG-02 — Wazuh Manager System Log Collection

> **Task:** Collect Wazuh server own system logs  
> **Author:** Mohamed Amine Namouchi  
> **Date:** June 3, 2026  
> **Status:** ✅ Complete

---

## Context

A SIEM that does not monitor itself is a critical blind spot.

If the Wazuh Manager server is compromised:
```
→ Attacker can modify rules and decoders silently
→ Attacker can disable active response scripts
→ No alerts generated about the attack
→ Entire security infrastructure neutralized
```

---

## Important Note — No wazuh-agent on Manager

On the Wazuh Manager server, it is **not possible** to install
`wazuh-agent` — apt will automatically remove `wazuh-manager`
as a conflicting package.

```
❌ DO NOT run: apt install wazuh-agent on the Manager server

Solution: Use agent ID 000 (built-in local agent)
The Manager monitors itself via its own ossec.conf localfile config
```

---

## OS Specificity — Debian 13

Debian 13 (trixie) does **not** use `/var/log/auth.log`.
Authentication events go through `journald` only.

```
Debian 11/12 : /var/log/auth.log ✅
Debian 13    : journald only ✅ (no auth.log)
```

---

## What Was Added

New log sources added to `/var/ossec/etc/ossec.conf` on the Manager:

| Source | Format | Security Value |
|--------|--------|---------------|
| `journald` | journald | SSH logins, sudo, PAM, system events (already present) |
| `/var/log/syslog` | syslog | General system events |
| `/var/log/dpkg.log` | syslog | Package installs/removals |
| `/var/ossec/logs/active-responses.log` | syslog | AR execution logs |

---

## Configuration

Added to the second `ossec_config` block in `/var/ossec/etc/ossec.conf`:

```xml
<ossec_config>
  <!-- journald — SSH + sudo + PAM events on Manager -->
  <localfile>
    <log_format>journald</log_format>
    <location>journald</location>
  </localfile>

  <!-- Active response logs -->
  <localfile>
    <log_format>syslog</log_format>
    <location>/var/ossec/logs/active-responses.log</location>
  </localfile>

  <!-- Package install/removal tracking -->
  <localfile>
    <log_format>syslog</log_format>
    <location>/var/log/dpkg.log</location>
  </localfile>

  <!-- Wazuh Manager system logs — Phase 3 LOG-02 -->
  <localfile>
    <log_format>syslog</log_format>
    <location>/var/log/syslog</location>
  </localfile>
</ossec_config>
```

---

## Additional Capabilities Active on Manager (agent 000)

| Capability | Status | Notes |
|------------|--------|-------|
| journald monitoring | ✅ Active | SSH + sudo + PAM events |
| SCA CIS Debian 13 | ✅ Active | Config assessment every 12h |
| Vulnerability Detection | ✅ Active | CVE scan on installed packages |
| Rootcheck | ✅ Active | Rootkit detection |
| Syscollector | ✅ Active | Hardware + OS + packages inventory |
| FIM | ✅ Active | /etc, /bin, /sbin, /boot |

---

## Validation

Confirmed working on 2026-06-03:

```
2026 Jun 03 16:20:48 wazuh->journald
Jun 03 14:20:47 wazuh sshd-session: pam_unix(sshd:auth):
authentication failure from ADMIN_IP user=admin

2026 Jun 03 16:21:14 wazuh->journald
Jun 03 14:21:13 wazuh sshd-session:
Accepted password for admin from ADMIN_IP
```

Manager self-monitoring confirmed — SSH events detected in real time. ✅

---

## Before vs After

```
BEFORE LOG-02:
Wazuh Manager → monitors agents only
Manager itself → completely unmonitored ❌

AFTER LOG-02:
Wazuh Manager → monitors agents ✅
              → monitors itself via agent 000 ✅
                  → journald (SSH + auth events)
                  → /var/log/syslog
                  → SCA + Vuln Detection + FIM
```

---

*Document maintained as part of Phase 3 — Optimisation & Hardening*  
*Last updated: June 2026*
