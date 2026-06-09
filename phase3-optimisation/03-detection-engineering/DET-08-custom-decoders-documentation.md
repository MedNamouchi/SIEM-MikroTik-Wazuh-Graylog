# DET-08 — Custom Decoders Documentation

> **Task:** Document all custom decoders  
> **Author:** Mohamed Amine Namouchi  
> **Date:** June 2026  
> **Status:** ✅ Complete

---

## Overview

All custom decoders are stored in:
```
/var/ossec/etc/decoders/local_decoder.xml
```

Pipeline:
```
MikroTik log → Graylog (CEF→Syslog) → rsyslog → /var/log/mikrotik.log
→ Wazuh Agent → Wazuh Manager → Decoders → Rules → Alerts
```

---

## Decoder 1 — mikrotik_graylog_identity (Parent)

**Purpose:** Parent decoder — matches any MikroTik log and extracts router name and log type.

**Prematch:** `msg:`

**Regex:**
```pcre2
msg:\s*([A-Z0-9\-]+)\[(FW|SYS|INFO)\]:
```

**Fields extracted:**
| Field | Example |
|-------|---------|
| `router_name` | OFIR_MAIN_NEW |
| `log_type` | FW, SYS, INFO |

**Sample log:**
```
2026-06-09T10:00:00Z graylog unknown source: 10.10.10.1 | message: CCR1009-7G-1C-1S+: [10, High] system,error,critical { msg: OFIR_MAIN_NEW[SYS]: login failure for user Test from 172.30.3.169 via winbox | device_vendor: MikroTik }
```

**Expected output:**
```
name        : mikrotik_graylog_identity
router_name : OFIR_MAIN_NEW
log_type    : SYS
```

---

## Decoder 2 — mikrotik-auth-success

**Purpose:** Detects successful logins on MikroTik routers.

**Parent:** `mikrotik_graylog_identity`

**Prematch:** `logged in from`

**Regex:**
```pcre2
msg: ([A-Z0-9_\-]+)\[INFO\]: user (\S+) logged in from (\S+) via (\S+)
```

**Fields extracted:**
| Field | Example |
|-------|---------|
| `router_name` | OFIR_MAIN_NEW |
| `user` | admin |
| `srcip` | 172.30.3.169 |
| `app` | winbox |

**Sample log:**
```
2026-06-09T10:00:00Z graylog unknown source: 10.10.10.1 | message: CCR1009-7G-1C-1S+: [10, High] system,info,account { msg: OFIR_MAIN_NEW[INFO]: user Test logged in from 172.30.3.169 via winbox | dvchost: OFIR_MAIN_NEW | app: winbox | src: 172.30.3.169 | device_vendor: MikroTik }
```

**Expected output:**
```
name        : mikrotik-auth-success
router_name : OFIR_MAIN_NEW
user        : Test
srcip       : 172.30.3.169
app         : winbox
→ Rule 100300 (level 3)
```

---

## Decoder 3 — mikrotik-auth-failure

**Purpose:** Detects failed login attempts on MikroTik routers.

**Parent:** `mikrotik_graylog_identity`

**Prematch:** `login failure`

**Regex:**
```pcre2
msg: ([A-Z0-9_\-]+)\[SYS\]: login failure for user (\S+) from (\S+) via (\S+)
```

**Fields extracted:**
| Field | Example |
|-------|---------|
| `router_name` | OFIR_MAIN_NEW |
| `dstuser` | Test |
| `srcip` | 172.30.3.169 |
| `app` | winbox |

**Sample log:**
```
2026-06-09T10:00:00Z graylog unknown source: 10.10.10.1 | message: CCR1009-7G-1C-1S+: [10, High] system,error,critical { msg: OFIR_MAIN_NEW[SYS]: login failure for user Test from 172.30.3.169 via winbox | dvchost: OFIR_MAIN_NEW | duser: Test | outcome: failure | src: 172.30.3.169 | app: winbox | device_vendor: MikroTik }
```

**Expected output:**
```
name        : mikrotik-auth-failure
router_name : OFIR_MAIN_NEW
dstuser     : Test
srcip       : 172.30.3.169
app         : winbox
→ Rule 100301 (level 5)
```

---

## Decoder 4 — mikrotik-auth-logout

**Purpose:** Detects user logouts from MikroTik routers.

**Parent:** `mikrotik_graylog_identity`

**Prematch:** `logged out from`

**Regex:**
```pcre2
msg: ([A-Z0-9_\-]+)\[INFO\]: user (\S+) logged out from (\S+) via (\S+)
```

**Fields extracted:**
| Field | Example |
|-------|---------|
| `router_name` | OFIR_MAIN_NEW |
| `user` | Test |
| `srcip` | 172.30.3.169 |
| `app` | winbox |

**Sample log:**
```
2026-06-09T10:00:00Z graylog unknown source: 10.10.10.1 | message: CCR1009-7G-1C-1S+: [10, High] system,info,account { msg: OFIR_MAIN_NEW[INFO]: user Test logged out from 172.30.3.169 via winbox | dvchost: OFIR_MAIN_NEW | app: winbox | src: 172.30.3.169 | device_vendor: MikroTik }
```

**Expected output:**
```
name        : mikrotik-auth-logout
router_name : OFIR_MAIN_NEW
dstuser     : Test
srcip       : 172.30.3.169
app         : winbox
→ Rule 100303 (level 3)
```

---

## Decoder 5 — mikrotik-reboot-conscious

**Purpose:** Detects intentional reboots triggered by a user.

**Parent:** `mikrotik_graylog_identity`

**Prematch:** `router rebooted by`

**Regex:**
```pcre2
msg: ([A-Z0-9_\-]+)\[SYS\]: router rebooted by ([^:]+):(\S+)@([\d\.]+)
```

**Fields extracted:**
| Field | Example |
|-------|---------|
| `router_name` | OFIR_MAIN_NEW |
| `reboot_method` | winbox |
| `user` | admin |
| `srcip` | 172.30.3.169 |

**Sample log:**
```
2026-06-09T10:00:00Z graylog unknown source: 10.10.10.1 | message: CCR1009-7G-1C-1S+: [10, High] system,info { msg: OFIR_MAIN_NEW[SYS]: router rebooted by winbox:admin@172.30.3.169 | dvchost: OFIR_MAIN_NEW | src: 172.30.3.169 | device_vendor: MikroTik }
```

**Expected output:**
```
name          : mikrotik-reboot-conscious
router_name   : OFIR_MAIN_NEW
reboot_method : winbox
user          : admin
srcip         : 172.30.3.169
→ Rule 100400 (level 8)
```

---

## Decoder 6 — mikrotik-reboot-unconscious

**Purpose:** Detects unexpected reboots (no user triggered).

**Parent:** `mikrotik_graylog_identity`

**Prematch:** `router rebooted \|`

**Regex:**
```pcre2
msg: ([A-Z0-9_\-]+)\[SYS\]: router rebooted
```

**Fields extracted:**
| Field | Example |
|-------|---------|
| `router_name` | OFIR_MAIN_NEW |

**Sample log:**
```
2026-06-09T10:00:00Z graylog unknown source: 10.10.10.1 | message: CCR1009-7G-1C-1S+: [10, High] system,info { msg: OFIR_MAIN_NEW[SYS]: router rebooted | dvchost: OFIR_MAIN_NEW | device_vendor: MikroTik }
```

**Expected output:**
```
name        : mikrotik-reboot-unconscious
router_name : OFIR_MAIN_NEW
→ Rule 100401 (level 12)
```

---

## Decoder 7 — mikrotik-reboot-cause

**Purpose:** Extracts the cause of an unexpected reboot/crash.

**Parent:** `mikrotik_graylog_identity`

**Prematch:** `System rebooted because`

**Regex:**
```pcre2
msg: ([A-Z0-9_\-]+)\[SYS\]: System rebooted because of ([^|]+?) \|
```

**Fields extracted:**
| Field | Example |
|-------|---------|
| `router_name` | OFIR_MAIN_NEW |
| `extra_data` | kernel fault |

**Sample log:**
```
2026-06-09T10:00:00Z graylog unknown source: 10.10.10.1 | message: CCR1009-7G-1C-1S+: [10, High] system,info { msg: OFIR_MAIN_NEW[SYS]: System rebooted because of kernel fault | dvchost: OFIR_MAIN_NEW | device_vendor: MikroTik }
```

**Expected output:**
```
name        : mikrotik-reboot-cause
router_name : OFIR_MAIN_NEW
extra_data  : kernel fault
→ Rule 100402 (level 13)
```

---

## Decoder 8 — mikrotik-config-changed

**Purpose:** Detects configuration changes on MikroTik routers.

**Parent:** `mikrotik_graylog_identity`

**Prematch:** `changed by`

**Regex:**
```pcre2
msg: ([A-Z0-9_\-]+)\[SYS\]: (.+) changed by ([^:]+):(\S+)@([\d\.]+)[^ ]* \(([^)]+)\)
```

**Fields extracted:**
| Field | Example |
|-------|---------|
| `router_name` | OFIR_MAIN_NEW |
| `change_type` | ip/firewall/filter |
| `access_method` | winbox |
| `user` | admin |
| `srcip` | 172.30.3.169 |
| `extra_data` | added |

**Sample log:**
```
2026-06-09T10:00:00Z graylog unknown source: 10.10.10.1 | message: CCR1009-7G-1C-1S+: [10, High] system,info { msg: OFIR_MAIN_NEW[SYS]: ip/firewall/filter changed by winbox:admin@172.30.3.169 (added) | dvchost: OFIR_MAIN_NEW | src: 172.30.3.169 | device_vendor: MikroTik }
```

**Expected output:**
```
name          : mikrotik-config-changed
router_name   : OFIR_MAIN_NEW
change_type   : ip/firewall/filter
access_method : winbox
user          : admin
srcip         : 172.30.3.169
extra_data    : added
→ Rule 100403 (level 5)
→ Rule 100404 (level 0) if access_method = scheduler
```

---

## Decoder 9 — mikrotik-resource-high

**Purpose:** Detects high CPU or memory usage on MikroTik routers.

**Parent:** `mikrotik_graylog_identity`

**Prematch:** `\[WARN\]: (CPU|MEMORY) HIGH`

**Regex:**
```pcre2
msg: \[WARN\]: (CPU|MEMORY) HIGH: (?:cpu-load|mem-usage)=(\d+)% on router ([A-Z0-9_\-]+)
```

**Fields extracted:**
| Field | Example |
|-------|---------|
| `resource_type` | CPU or MEMORY |
| `resource_value` | 87 |
| `router_name` | OFIR_MAIN_NEW |

**Sample logs:**

CPU HIGH:
```
2026-06-09T10:00:00Z graylog unknown source: 10.10.10.1 | message: CCR1009-7G-1C-1S+: [8, Low] system,info { msg: [WARN]: CPU HIGH: cpu-load=87% on router OFIR_MAIN_NEW | dvchost: OFIR_MAIN_NEW | device_vendor: MikroTik }
```

MEMORY HIGH:
```
2026-06-09T10:00:00Z graylog unknown source: 10.10.10.1 | message: CCR1009-7G-1C-1S+: [8, Low] system,info { msg: [WARN]: MEMORY HIGH: mem-usage=92% on router OFIR_MAIN_NEW | dvchost: OFIR_MAIN_NEW | device_vendor: MikroTik }
```

**Expected output:**
```
CPU:    resource_type=CPU,    resource_value=87  → Rule 100500 (level 8)
MEMORY: resource_type=MEMORY, resource_value=92  → Rule 100501 (level 8)
```

---

## Decoder 10 — mikrotik-firewall

**Purpose:** Detects firewall events (accept/drop) on MikroTik routers.

**Parent:** `mikrotik_graylog_identity`

**Prematch:** `\[FW\]:`

**Regex:**
```pcre2
msg: ([A-Z0-9_\-]+)\[FW\]: ([\w\s\-]+?) (\w+): in:([\w\s\-]+?) out:([\w\s\-]+?), connection-state:(\w+) .+?, (\d+\.\d+\.\d+\.\d+):(\d+)->(\d+\.\d+\.\d+\.\d+):(\d+), len (\d+).+?act: (\w+)
```

**Fields extracted:**
| Field | Example |
|-------|---------|
| `router_name` | OFIR_MAIN_NEW |
| `rule_name` | DROP FORWARD |
| `fw_direction` | forward |
| `in_interface` | BRIDGE |
| `out_interface` | WG-Ofir |
| `connection_state` | new |
| `src_ip` | 192.168.1.50 |
| `src_port` | 41615 |
| `dst_ip` | 10.15.0.30 |
| `dst_port` | 10051 |
| `packet_len` | 60 |
| `fw_action` | drop |

> ⚠️ Note: `fw_action` requires the CEF `act:` field to be present in the log.
> It is appended by Graylog from the CEF output plugin.

**Sample log:**
```
2026-06-09T10:00:00Z graylog unknown source: 10.10.10.1 | message: CCR1009-7G-1C-1S+: [8, Low] firewall,info { msg: OFIR_MAIN_NEW[FW]: DROP FORWARD forward: in:BRIDGE out:WG-Ofir, connection-state:new src-mac 64:16:7f:c9:cd:cf, proto TCP (SYN), 192.168.1.50:41615->10.15.0.30:10051, len 60 | device_version: 7.20.6 (stable) | device_product: CCR1009-7G-1C-1S+ | act: drop | dvchost: OFIR_MAIN_NEW | device_vendor: MikroTik }
```

**Expected output:**
```
name             : mikrotik-firewall
router_name      : OFIR_MAIN_NEW
fw_action        : drop
in_interface     : BRIDGE
src_ip           : 192.168.1.50
dst_ip           : 10.15.0.30
→ Rule 100202 (level 8) if fw_action=drop + internal IP
→ Rule 100206 (level 9) if src_ip is external
→ Rule 100207 (level 6) if in_interface=VPN_INTERFACE
```

---

## Decoder Summary

| Decoder | Parent | Triggers Rule(s) |
|---------|--------|-----------------|
| mikrotik_graylog_identity | — | Parent only |
| mikrotik-auth-success | identity | 100300 |
| mikrotik-auth-failure | identity | 100301, 100302 |
| mikrotik-auth-logout | identity | 100303 |
| mikrotik-reboot-conscious | identity | 100400 |
| mikrotik-reboot-unconscious | identity | 100401 |
| mikrotik-reboot-cause | identity | 100402 |
| mikrotik-config-changed | identity | 100403, 100404 |
| mikrotik-resource-high | identity | 100500, 100501 |
| mikrotik-firewall | identity | 100200-100207 |

---

*Document maintained as part of Phase 3 — Optimisation & Hardening*  
*Last updated: June 2026*
