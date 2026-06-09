# DET-06 — Rule Testing Samples & Validation

> **Task:** Test all existing rules with wazuh-logtest  
> **Author:** Mohamed Amine Namouchi  
> **Date:** June 2026  
> **Status:** ✅ Complete

---

## How to Use This Document

```bash
# Launch wazuh-logtest on the Wazuh Manager
/var/ossec/bin/wazuh-logtest

# Paste any sample log below
# Compare output with expected result
```

---

## Fixes Applied During Testing

| Issue | Fix |
|-------|-----|
| `fw_action` not extracted by decoder | Added `fw_action` to mikrotik-firewall decoder regex |
| Rule 100206 triggered on internal IPs (172.30.x.x) | Fixed PCRE2 regex to exclude full RFC1918 172.16.0.0/12 range |
| Rule 100203 description had placeholder | Replaced `ROUTER_NAME` with `OFIR_MAIN_NEW` |
| Rules 100201 and 100204 never matched | Removed — 100201 too noisy, 100204 not applicable (nginx proxy) |

---

## Firewall Rules

### Rule 100200 — Firewall Parent Event

```
2026-06-09T10:00:00Z graylog unknown source: 10.10.10.1 | message: CCR1009-7G-1C-1S+: [8, Low] firewall,info { msg: OFIR_MAIN_NEW[FW]: DROP FORWARD forward: in:BRIDGE out:WG-Ofir, connection-state:new src-mac 64:16:7f:c9:cd:cf, proto TCP (SYN), 192.168.1.50:41615->10.15.0.30:10051, len 60 | device_version: 7.20.6 (stable) | act: drop | dvchost: OFIR_MAIN_NEW | device_vendor: MikroTik }
```

**Expected:**
```
decoder : mikrotik-firewall
rule    : 100200
level   : 3
```
**Status:** ✅ PASS

---

### Rule 100202 — Blocked Connection

```
2026-06-09T10:00:00Z graylog unknown source: 10.10.10.1 | message: CCR1009-7G-1C-1S+: [8, Low] firewall,info { msg: OFIR_MAIN_NEW[FW]: DROP FORWARD forward: in:BRIDGE out:WG-Ofir, connection-state:new src-mac 64:16:7f:c9:cd:cf, proto TCP (SYN), 192.168.1.50:41615->10.15.0.30:10051, len 60 | device_version: 7.20.6 (stable) | device_product: CCR1009-7G-1C-1S+ | act: drop | dvchost: OFIR_MAIN_NEW | device_vendor: MikroTik }
```

**Expected:**
```
decoder  : mikrotik-firewall
fw_action: drop
rule     : 100202
level    : 8
```
**Status:** ✅ PASS

---

### Rule 100203 — Event on Main Router (OFIR_MAIN_NEW)

```
2026-06-09T10:00:00Z graylog unknown source: 10.10.10.1 | message: CCR1009-7G-1C-1S+: [8, Low] firewall,info { msg: OFIR_MAIN_NEW[FW]: DROP FORWARD forward: in:BRIDGE out:WG-Ofir, connection-state:new src-mac 64:16:7f:c9:cd:cf, proto TCP (SYN), 172.30.2.78:41615->10.15.0.30:10051, len 60 | device_version: 7.20.6 (stable) | act: drop | dvchost: OFIR_MAIN_NEW | device_vendor: MikroTik }
```

**Expected:**
```
decoder     : mikrotik-firewall
router_name : OFIR_MAIN_NEW
rule        : 100203
level       : 5
```
**Status:** ✅ PASS

---

### Rule 100205 — Port Scan Detection

**Status:** ⏸️ NOT TESTED

> MikroTik only logs connections matching a firewall rule with logging enabled.
> TCP conn-refused events are not logged.
> To validate: monitor alerts.log during a real external port scan in production.

**Expected when triggered:**
```
rule  : 100205
level : 10
group : recon,port_scan
```

---

### Rule 100206 — External Inbound Traffic

```
2026-06-09T10:00:00Z graylog unknown source: 10.10.10.1 | message: CCR1009-7G-1C-1S+: [8, Low] firewall,info { msg: OFIR_MAIN_NEW[FW]: DROP FORWARD forward: in:BRIDGE out:WG-Ofir, connection-state:new src-mac 64:16:7f:c9:cd:cf, proto TCP (SYN), 77.83.39.235:41615->10.15.0.30:10051, len 60 | device_version: 7.20.6 (stable) | device_product: CCR1009-7G-1C-1S+ | act: drop | dvchost: OFIR_MAIN_NEW | device_vendor: MikroTik }
```

**Expected:**
```
decoder : mikrotik-firewall
src_ip  : 77.83.39.235 (external)
rule    : 100206
level   : 9
```
**Status:** ✅ PASS

> Note: Internal IPs (10.x, 172.16-31.x, 192.168.x) do NOT trigger this rule.
> Verified: 172.30.2.78 correctly falls back to 100202/100203.

---

### Rule 100207 — VPN Traffic

```
2026-06-09T10:00:00Z graylog unknown source: 10.10.10.1 | message: CCR1009-7G-1C-1S+: [8, Low] firewall,info { msg: OFIR_MAIN_NEW[FW]: ACCEPT FORWARD forward: in:VPN_INTERFACE out:BRIDGE, connection-state:new src-mac 64:16:7f:c9:cd:cf, proto TCP (SYN), 192.168.1.50:41615->10.15.0.30:10051, len 60 | act: accept | dvchost: OFIR_MAIN_NEW | device_vendor: MikroTik }
```

**Expected:**
```
decoder      : mikrotik-firewall
in_interface : VPN_INTERFACE
rule         : 100207
level        : 6
```
**Status:** ✅ PASS

---

## Authentication Rules

### Rule 100300 — Login Success

```
2026-06-09T10:00:00Z graylog unknown source: 10.10.10.1 | message: CCR1009-7G-1C-1S+: [10, High] system,info,account { msg: OFIR_MAIN_NEW[INFO]: user Test logged in from 172.30.3.169 via winbox | dvchost: OFIR_MAIN_NEW | app: winbox | src: 172.30.3.169 | device_vendor: MikroTik }
```

**Expected:**
```
decoder : mikrotik-auth-success
rule    : 100300
level   : 3
mitre   : T1078
```
**Status:** ✅ PASS

---

### Rule 100301 — Login Failure

```
2026-06-09T10:00:00Z graylog unknown source: 10.10.10.1 | message: CCR1009-7G-1C-1S+: [10, High] system,error,critical { msg: OFIR_MAIN_NEW[SYS]: login failure for user Test from 172.30.3.169 via winbox | dvchost: OFIR_MAIN_NEW | duser: Test | outcome: failure | src: 172.30.3.169 | app: winbox | device_vendor: MikroTik }
```

**Expected:**
```
decoder : mikrotik-auth-failure
rule    : 100301
level   : 5
mitre   : T1110
```
**Status:** ✅ PASS

---

### Rule 100302 — Brute Force

> Tested in production — 5+ failures from same IP in 60 seconds.

**Expected:**
```
rule  : 100302
level : 10
mitre : T1110.001
```
**Status:** ✅ PASS (production)

---

### Rule 100303 — Logout

```
2026-06-09T10:00:00Z graylog unknown source: 10.10.10.1 | message: CCR1009-7G-1C-1S+: [10, High] system,info,account { msg: OFIR_MAIN_NEW[INFO]: user Test logged out from 172.30.3.169 via winbox | dvchost: OFIR_MAIN_NEW | app: winbox | src: 172.30.3.169 | device_vendor: MikroTik }
```

**Expected:**
```
decoder : mikrotik-auth-logout
rule    : 100303
level   : 3
mitre   : T1078
```
**Status:** ✅ PASS

---

### Rule 100304 — Login Success After Failures

**Status:** ⏸️ PENDING FIX

> Wazuh cannot correlate two different decoders in a single rule.
> Current implementation does not fire reliably.
> To be fixed in a future iteration.

---

## System Rules

### Rule 100400 — Conscious Reboot

```
2026-06-09T10:00:00Z graylog unknown source: 10.10.10.1 | message: CCR1009-7G-1C-1S+: [10, High] system,info { msg: OFIR_MAIN_NEW[SYS]: router rebooted by winbox:admin@172.30.3.169 | dvchost: OFIR_MAIN_NEW | src: 172.30.3.169 | device_vendor: MikroTik }
```

**Expected:**
```
decoder : mikrotik-reboot-conscious
rule    : 100400
level   : 8
mitre   : T1529
```
**Status:** ✅ PASS

---

### Rule 100401 — Unexpected Reboot

```
2026-06-09T10:00:00Z graylog unknown source: 10.10.10.1 | message: CCR1009-7G-1C-1S+: [10, High] system,info { msg: OFIR_MAIN_NEW[SYS]: router rebooted | dvchost: OFIR_MAIN_NEW | device_vendor: MikroTik }
```

**Expected:**
```
decoder : mikrotik-reboot-unconscious
rule    : 100401
level   : 12
mitre   : T1529
```
**Status:** ✅ PASS

---

### Rule 100402 — Router Crash Cause

```
2026-06-09T10:00:00Z graylog unknown source: 10.10.10.1 | message: CCR1009-7G-1C-1S+: [10, High] system,info { msg: OFIR_MAIN_NEW[SYS]: System rebooted because of kernel fault | dvchost: OFIR_MAIN_NEW | device_vendor: MikroTik }
```

**Expected:**
```
decoder    : mikrotik-reboot-cause
extra_data : kernel fault
rule       : 100402
level      : 13
```
**Status:** ✅ PASS

---

### Rule 100403 — Config Change

```
2026-06-09T10:00:00Z graylog unknown source: 10.10.10.1 | message: CCR1009-7G-1C-1S+: [10, High] system,info { msg: OFIR_MAIN_NEW[SYS]: ip/firewall/filter changed by winbox:admin@172.30.3.169 (added) | dvchost: OFIR_MAIN_NEW | src: 172.30.3.169 | device_vendor: MikroTik }
```

**Expected:**
```
decoder     : mikrotik-config-changed
change_type : ip/firewall/filter
rule        : 100403
level       : 5
mitre       : T1562
```
**Status:** ✅ PASS

---

### Rule 100404 — WireGuard Scheduler Suppression

```
2026-06-09T10:00:00Z graylog unknown source: 10.10.10.1 | message: CCR1009-7G-1C-1S+: [10, High] system,info { msg: OFIR_MAIN_NEW[SYS]: ip/firewall/filter changed by scheduler:auto-update@172.30.3.169 (modified) | dvchost: OFIR_MAIN_NEW | src: 172.30.3.169 | device_vendor: MikroTik }
```

**Expected:**
```
decoder : mikrotik-config-changed
rule    : 100404
level   : 0  ← suppressed
```
**Status:** ✅ PASS

---

## Resource Monitoring Rules

### Rule 100500 — CPU HIGH

```
2026-06-09T10:00:00Z graylog unknown source: 10.10.10.1 | message: CCR1009-7G-1C-1S+: [8, Low] system,info { msg: [WARN]: CPU HIGH: cpu-load=87% on router OFIR_MAIN_NEW | dvchost: OFIR_MAIN_NEW | device_vendor: MikroTik }
```

**Expected:**
```
decoder        : mikrotik-resource-high
resource_type  : CPU
resource_value : 87
rule           : 100500
level          : 8
mitre          : T1496
```
**Status:** ✅ PASS

---

### Rule 100501 — MEMORY HIGH

```
2026-06-09T10:00:00Z graylog unknown source: 10.10.10.1 | message: CCR1009-7G-1C-1S+: [8, Low] system,info { msg: [WARN]: MEMORY HIGH: mem-usage=92% on router OFIR_MAIN_NEW | dvchost: OFIR_MAIN_NEW | device_vendor: MikroTik }
```

**Expected:**
```
decoder        : mikrotik-resource-high
resource_type  : MEMORY
resource_value : 92
rule           : 100501
level          : 8
mitre          : T1496
```
**Status:** ✅ PASS

---

## Agent Monitoring Rules

### Rules 100600 / 100601 — Agent Stopped / Disconnected

> Tested in production — agent stopped and Mattermost notification received.

**Expected:**
```
100600 : Agent stopped    → level 10 → Mattermost + email
100601 : Agent disconnect → level 12 → Mattermost + email
```
**Status:** ✅ PASS (production)

---

## Advanced Detection Rules

### Rules 100700 / 100701 — Password Spraying / Distributed Attack

> Frequency rules — cannot be reliably tested with wazuh-logtest.
> Mechanism validated via rule 100302 (same frequency pattern).

**Status:** ⏸️ PENDING PRODUCTION TEST

---

## Summary

| Rule | Description | Status |
|------|-------------|--------|
| 100200 | Firewall parent | ✅ PASS |
| 100202 | Blocked connection | ✅ PASS |
| 100203 | Main router event | ✅ PASS |
| 100205 | Port scan | ⏸️ Not tested |
| 100206 | External traffic | ✅ PASS |
| 100207 | VPN traffic | ✅ PASS |
| 100300 | Login success | ✅ PASS |
| 100301 | Login failure | ✅ PASS |
| 100302 | Brute force | ✅ PASS (prod) |
| 100303 | Logout | ✅ PASS |
| 100304 | Login after failures | ⏸️ Pending fix |
| 100400 | Conscious reboot | ✅ PASS |
| 100401 | Unexpected reboot | ✅ PASS |
| 100402 | Crash cause | ✅ PASS |
| 100403 | Config change | ✅ PASS |
| 100404 | WireGuard suppression | ✅ PASS |
| 100500 | CPU HIGH | ✅ PASS |
| 100501 | MEMORY HIGH | ✅ PASS |
| 100600 | Agent stopped | ✅ PASS (prod) |
| 100601 | Agent disconnected | ✅ PASS (prod) |
| 100700 | Password spraying | ⏸️ Pending prod test |
| 100701 | Distributed attack | ⏸️ Pending prod test |

---

*Document maintained as part of Phase 3 — Optimisation & Hardening*  
*Last updated: June 2026*
