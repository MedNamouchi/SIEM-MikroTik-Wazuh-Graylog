# DET-07 — Multi-Source Correlation Rule

> **Task:** Create multi-source correlation rule  
> **Author:** Mohamed Amine Namouchi  
> **Date:** June 2026  
> **Status:** ✅ Complete

---

## Context

A single brute force on one system is suspicious.
The same IP attacking multiple systems simultaneously is a coordinated attack.

```
Attacker scans OFIR infrastructure:
→ Brute forces MikroTik routers via Winbox/SSH
→ Simultaneously brute forces Graylog server via SSH
→ Same IP — same attacker — coordinated campaign

Without correlation: 2 separate alerts, easy to miss
With DET-07: 1 CRITICAL level 15 alert — immediate response
```

---

## Rules Added

### Rule 100800 — MikroTik BF + SSH BF (rule 5712)

```xml
<rule id="100800" level="15" timeframe="300">
  <if_matched_sid>100302</if_matched_sid>
  <if_matched_sid>5712</if_matched_sid>
  <same_source_ip/>
  <description>CRITICAL: Same IP $(srcip) brute forcing
  MikroTik AND SSH — coordinated attack!</description>
  <group>bruteforce,correlation,gdpr_IV_35.7.d,gdpr_IV_32.2,
  nist_800_53_AC.7,pci_dss_10.2.4,pci_dss_11.4,</group>
  <mitre>
    <id>T1110</id>
  </mitre>
</rule>
```

### Rule 100801 — MikroTik BF + SSH BF (rule 5763)

```xml
<rule id="100801" level="15" timeframe="300">
  <if_matched_sid>100302</if_matched_sid>
  <if_matched_sid>5763</if_matched_sid>
  <same_source_ip/>
  <description>CRITICAL: Same IP $(srcip) brute forcing
  MikroTik AND SSH — coordinated attack!</description>
  <group>bruteforce,correlation,gdpr_IV_35.7.d,gdpr_IV_32.2,
  nist_800_53_AC.7,pci_dss_10.2.4,pci_dss_11.4,</group>
  <mitre>
    <id>T1110</id>
  </mitre>
</rule>
```

---

## Detection Logic

```
Rule 100302 fires (MikroTik brute force from IP X)
         +
Rule 5712 or 5763 fires (SSH brute force from same IP X)
         ↓
Within 300 seconds (5 minutes)
         ↓
Rule 100800/100801 fires → Level 15 CRITICAL
         ↓
mattermost-correlation-alert.sh executes on Manager
         ↓
Mattermost + Email → IMMEDIATE ACTION REQUIRED
```

---

## Active Response

Script: `mattermost-correlation-alert.sh`
Location: **server** (runs on Wazuh Manager)

```xml
<command>
  <name>mattermost-correlation-alert</name>
  <executable>mattermost-correlation-alert.sh</executable>
  <timeout_allowed>no</timeout_allowed>
</command>
<active-response>
  <command>mattermost-correlation-alert</command>
  <location>server</location>
  <rules_id>100800,100801</rules_id>
</active-response>
```

---

## Notification Example

```
🚨🚨🚨 COORDINATED ATTACK DETECTED 🚨🚨🚨
Source IP : ATTACKER_IP
Attack    : MikroTik Brute Force + SSH Brute Force from SAME IP
Rule      : 100800
Level     : 15/15 ← MAXIMUM
Timestamp : 2026-06-09T15:18:02

⚠️ IMMEDIATE ACTION REQUIRED:
→ Block IP on all routers
→ Block IP on Graylog server
→ Check for successful logins
→ Verify no persistence established
```

---

## Validation

Confirmed working on 2026-06-09:
- Simulated MikroTik brute force + SSH brute force from same IP
- Rule 100800 fired at level 15 ✅
- Mattermost notification received ✅
- Email notification received ✅

---

## MITRE ATT&CK Coverage

| Technique | ID | Description |
|-----------|-----|-------------|
| Brute Force | T1110 | Credential Access via multiple attempts |
| Valid Accounts | T1078 | If brute force succeeds |

---

*Document maintained as part of Phase 3 — Optimisation & Hardening*  
*Last updated: June 2026*
