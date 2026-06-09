# DET-03 — CDB Lists for Authorized Admin IPs

> **Task:** Create CDB Lists for authorized admin IPs  
> **Author:** Mohamed Amine Namouchi  
> **Date:** June 2026  
> **Status:** ✅ Complete

---

## Context

Without a whitelist, every legitimate admin connection to MikroTik
routers triggers alerts — login success, config changes, etc.

```
Admin connects to router → Rule 100300 fires → Mattermost alert
Admin makes config change → Rule 100403 fires → Mattermost alert
→ Noise that masks real threats
```

A CDB List allows rules to check if a source IP is a known admin
and reduce the alert level or suppress it entirely.

---

## What is a CDB List

```
CDB = Constant Database
→ Simple key:value text file
→ Wazuh compiles it for fast lookups
→ Rules can query it with <list> field
→ Used for whitelist / blacklist / enrichment
```

---

## File Location

```
/var/ossec/etc/lists/authorized-admin-ips
```

---

## Format

```
IP_ADDRESS:role
```

Example:
```
ADMIN_WORKSTATION_IP:admin_workstation
GRAYLOG_IP:siem_component
WAZUH_MANAGER_IP:siem_component
SCANNER_IP:network_scanner
```

---

## Configuration

### 1. Register in ossec.conf (Manager)

Added to the `<ruleset>` section:

```xml
<list>etc/lists/authorized-admin-ips</list>
```

### 2. How to use in a rule

```xml
<!-- Suppress alert if source IP is an authorized admin -->
<rule id="100700" level="0">
  <if_sid>100300</if_sid>
  <list field="srcip" lookup="match_key">etc/lists/authorized-admin-ips</list>
  <description>MikroTik: Login from authorized admin IP — suppressed</description>
</rule>
```

---

## Maintenance

When a new admin workstation is added:

```bash
# Add new IP to the list
echo "NEW_IP:admin_workstation" >> /var/ossec/etc/lists/authorized-admin-ips

# Restart manager to reload the list
systemctl restart wazuh-manager
```
---

*Document maintained as part of Phase 3 — Optimisation & Hardening*  
*Last updated: June 2026*
