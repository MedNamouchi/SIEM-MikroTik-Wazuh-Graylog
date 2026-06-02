# Log Format Documentation — Wazuh Decoder Input

> **INF-04** — Document exact log format expected by Wazuh decoders  
> **Author:** Mohamed Amine Namouchi  
> **Date:** June 2026  
> **Status:** ✅ Complete

---

## ⚠️ Critical Warning

The Wazuh decoders expect a **specific log format produced by Graylog's syslog output plugin**.  
If the Graylog output plugin is modified, the format may change silently — causing decoders to stop matching and **zero alerts to be generated**, with no visible error.

**Before modifying any Graylog configuration, always test decoders with `wazuh-logtest` afterwards.**

---

## Pipeline Overview

```
MikroTik Router
    → CEF format over TLS (port 6514)
        ↓
Graylog 7.0
    → Receives CEF
    → Converts to Syslog via output plugin (format: full)
    → Forwards to rsyslog on localhost:514
        ↓
rsyslog
    → Writes to /var/log/mikrotik.log
        ↓
Wazuh Agent
    → Reads /var/log/mikrotik.log
    → Forwards to Wazuh Manager (AES-256)
        ↓
Wazuh Manager
    → Applies PCRE2 decoders
    → Applies detection rules
```

---

## General Line Structure

Every line in `/var/log/mikrotik.log` follows this structure:

```
TIMESTAMP graylog unknown source: ROUTER_IP | message: DEVICE_MODEL: [EVENT_ID, SEVERITY] EVENT_TYPE { msg: ROUTER_NAME[TYPE]: CONTENT | FIELD1: VALUE1 | FIELD2: VALUE2 | ... }
```

### Fixed Fields (always present)

| Field | Example | Description |
|-------|---------|-------------|
| Timestamp | `2026-06-02T15:04:32Z` | ISO 8601 UTC — written by rsyslog |
| Source tag | `graylog` | Fixed string — identifies the log source |
| Router IP | `ROUTER_IP` | IP of the MikroTik router |
| Device model | `CCR1009-7G-1C-1S+` | RouterOS hardware model |
| Event ID | `8` | Numeric severity class from MikroTik |
| Severity label | `Low` / `High` | Text severity from MikroTik |
| Event type | `firewall,info` / `system,error,critical` | MikroTik log topic |
| Router name | `ROUTER_NAME` | Real hostname of the router |
| Log type tag | `[FW]` / `[SYS]` / `[INFO]` | Log category inserted by Graylog stream |

### Variable Graylog Metadata Fields (pipe-separated)

| Field | Example | Description |
|-------|---------|-------------|
| `device_version` | `7.20.6 (stable)` | RouterOS firmware version |
| `device_product` | `CCR1009-7G-1C-1S+` | Hardware model |
| `dvchost` | `ROUTER_NAME` | Router hostname |
| `dvc` | `ROUTER_IP` | Router IP |
| `gl2_remote_ip` | `ROUTER_IP` | Graylog remote IP |
| `gl2_receive_timestamp` | `2026-06-02 13:04:32.810` | Graylog reception time |
| `gl2_processing_timestamp` | `2026-06-02 13:04:32.811` | Graylog processing time |
| `timestamp` | `2026-06-02T15:04:28.000+02:00` | Original MikroTik event time |
| `severity` | `Low` / `High` | Severity label |
| `event_class_id` | `8` | Numeric event class |
| `device_vendor` | `MikroTik` | Always MikroTik |
| `_id` | `xxxxxxxx-xxxx-...` | Graylog internal message UUID |
| `gl2_message_id` | `01KT46YYV00BFG5YN6MNZ1SF37` | Graylog message ID |

---

## Log Types — Anonymized Examples

### Type 1 — Firewall Event `[FW]`

**Trigger:** MikroTik firewall rule match (forward, accept, drop)

**Raw line:**
```
2026-06-02T15:04:32Z graylog unknown source: ROUTER_IP | message: CCR1009-7G-1C-1S+: [8, Low] firewall,info { msg: ROUTER_NAME[FW]: RULE_NAME forward: in:VPN_INTERFACE out:LAN_INTERFACE, connection-state:new proto TCP (SYN), WG_CLIENT_IP:41734->INTERNAL_SERVER_1:10050, len 60 | device_version: 7.20.6 (stable) | dst: INTERNAL_SERVER_1 | act: accept | deviceInboundInterface: VPN_INTERFACE | deviceOutboundInterface: LAN_INTERFACE | src: WG_CLIENT_IP | spt: 41734 | dpt: 10050 | proto: tcp | severity: Low | dvchost: ROUTER_NAME | device_vendor: MikroTik }
```

**Key fields extracted by decoder:**

| Field | Value | Decoder variable |
|-------|-------|-----------------|
| Router name | `ROUTER_NAME` | `router_id` |
| Log type | `FW` | `log_type` |
| Source IP | `WG_CLIENT_IP` | `srcip` |
| Destination IP | `INTERNAL_SERVER_1` | `dstip` |
| Source port | `41734` | `srcport` |
| Destination port | `10050` | `dstport` |
| Protocol | `tcp` | `proto` |
| Action | `accept` | `action` |
| In interface | `VPN_INTERFACE` | `in_interface` |
| Out interface | `LAN_INTERFACE` | `out_interface` |

---

### Type 2 — Authentication Failure `[SYS]`

**Trigger:** Failed login attempt on the router

**Raw line:**
```
2026-06-02T14:30:32Z graylog unknown source: ROUTER_IP | message: CCR1009-7G-1C-1S+: [10, High] system,error,critical { msg: ROUTER_NAME[SYS]: login failure for user ADMIN_USER from ADMIN_IP via winbox | device_version: 7.20.6 (stable) | dvchost: ROUTER_NAME | duser: ADMIN_USER | outcome: failure | app: winbox | severity: High | src: ADMIN_IP | event_class_id: 10 | name: system,error,critical | device_vendor: MikroTik }
```

**Key fields extracted by decoder:**

| Field | Value | Decoder variable |
|-------|-------|-----------------|
| Router name | `ROUTER_NAME` | `router_id` |
| Log type | `SYS` | `log_type` |
| Username | `ADMIN_USER` | `dstuser` |
| Source IP | `ADMIN_IP` | `srcip` |
| Access method | `winbox` | `access_method` |
| Outcome | `failure` | `login_status` |

---

### Type 3 — Successful Login `[INFO]`

**Trigger:** Successful login on the router

**Raw line:**
```
2026-06-02T14:30:35Z graylog unknown source: ROUTER_IP | message: CCR1009-7G-1C-1S+: [10, Low] system,info,account { msg: ROUTER_NAME[INFO]: user ADMIN_USER logged in from ADMIN_IP via winbox | device_version: 7.20.6 (stable) | dvchost: ROUTER_NAME | duser: ADMIN_USER | outcome: success | app: winbox | severity: Low | src: ADMIN_IP | event_class_id: 10 | name: system,info,account | device_vendor: MikroTik }
```

**Key fields extracted by decoder:**

| Field | Value | Decoder variable |
|-------|-------|-----------------|
| Router name | `ROUTER_NAME` | `router_id` |
| Log type | `INFO` | `log_type` |
| Username | `ADMIN_USER` | `dstuser` |
| Source IP | `ADMIN_IP` | `srcip` |
| Access method | `winbox` | `access_method` |
| Outcome | `success` | `login_status` |

---

### Type 4 — System/Config Event `[SYS]`

**Trigger:** Configuration change, WireGuard peer update, scheduler action

**Raw line:**
```
2026-06-02T15:05:36Z graylog unknown source: ROUTER_IP | message: CCR1009-7G-1C-1S+: [10, Low] system,info { msg: ROUTER_NAME[SYS]: wireguard peer entry changed by scheduler:WG-Provjera Peer/script:WG-Provjera Peer/action:698621 (/interface wireguard peers set *7B endpoint-address=WG_ENDPOINT) | device_version: 7.20.6 (stable) | dvchost: ROUTER_NAME | severity: Low | event_class_id: 10 | name: system,info | device_vendor: MikroTik }
```

**Key fields extracted by decoder:**

| Field | Value | Decoder variable |
|-------|-------|-----------------|
| Router name | `ROUTER_NAME` | `router_id` |
| Log type | `SYS` | `log_type` |
| Change details | `wireguard peer entry changed by scheduler:...` | `extra_data` |

> ℹ️ Note: WireGuard scheduler config changes are suppressed by a dedicated rule
> to avoid alert flooding from legitimate automated updates.

---

### Type 5 — Reboot Event `[SYS]`

**Trigger:** Router reboot (conscious or unexpected)

> ⚠️ No recent example available in logs — router has been stable.  
> Refer to Phase 2 decoder documentation for regex details.

**Expected format:**
```
TIMESTAMP graylog unknown source: ROUTER_IP | message: DEVICE: [ID, SEV] system,info { msg: ROUTER_NAME[SYS]: system rebooted by ADMIN_USER from ADMIN_IP via METHOD | ... }
```

---

### Type 6 — Resource Event `[INFO]`

**Trigger:** CPU or RAM exceeds defined threshold

> ⚠️ No recent example available in logs — thresholds not exceeded today.  
> Refer to Phase 2 decoder documentation for regex details.

**Expected format:**
```
TIMESTAMP graylog unknown source: ROUTER_IP | message: DEVICE: [ID, SEV] system,info { msg: ROUTER_NAME[INFO]: cpu load: XX% | ... }
```

---

## Decoder Dependency Map

```
Log arrives at Wazuh Manager
        ↓
mikrotik_graylog_identity (parent decoder)
    → Matches: "graylog unknown source"
    → Extracts: router_id, log_type
        ↓
Child decoder selected based on log_type:
    [FW]   → mikrotik-firewall
    [SYS]  → mikrotik-auth / mikrotik-config-changed /
              mikrotik-reboot-conscious / mikrotik-reboot-unconscious
    [INFO] → mikrotik-resource-high / mikrotik-login-info
```

---

## Rules Triggered by Each Log Type

| Log Type | Rule IDs | Detection |
|----------|----------|-----------|
| `[FW]` auth failure | 100301, 100302, 110016 | Brute force, targeted attack |
| `[FW]` firewall | 100205, 100206, 100207, 100204 | Port scan, external traffic, VPN, web server |
| `[SYS]` reboot | 100400, 100401, 100402 | Conscious/unexpected reboot, crash |
| `[INFO]` resource | 100500, 100501 | CPU HIGH, MEMORY HIGH |

---

## Files to Watch (Fragility Points)

| File | Risk if modified |
|------|-----------------|
| `/etc/graylog/server/server.conf` | Graylog output format may change → decoders break silently |
| Graylog output plugin config | Format changes from `full` to `plain` → `msg:` field stripped |
| `/etc/rsyslog.d/graylog-wazuh.conf` | Log file path may change → agent stops reading |
| `/var/ossec/etc/decoders/mikrotik-decoder.xml` | Decoders modified → rules stop matching |

---

## How to Validate After Any Change

```bash
# Test a sample log against the decoder
echo 'PASTE_LOG_LINE_HERE' | /var/ossec/bin/wazuh-logtest

# Expected output:
# **Phase 1: Completed filtering (rules)
# Rule id: 100302
# decoder: mikrotik_graylog_identity
```

If no rule fires after a Graylog config change → check the log format first.

---

*Document maintained as part of Phase 3 — Optimisation & Hardening*  
*Last updated: June 2026*
