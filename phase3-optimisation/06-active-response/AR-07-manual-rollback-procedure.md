# AR-07 — Manual Rollback Procedure

> **Task:** Write manual rollback procedure  
> **Author:** Mohamed Amine Namouchi  
> **Date:** June 2026  
> **Status:** ✅ Complete

---

## Context

The `iptables-block.sh` active response script automatically blocks
attacker IPs for 10 minutes. If it fires incorrectly on a legitimate
IP, follow this procedure to unblock immediately.

---

## Step 1 — Identify Blocked IPs

Connect to the Graylog server and list blocked IPs:

```bash
iptables -L INPUT -n | grep DROP
```

Example output:
```
DROP  all  --  77.83.39.235  0.0.0.0/0
```

---

## Step 2 — Unblock the IP

```bash
iptables -D INPUT -s IP_TO_UNBLOCK -j DROP
```

Example:
```bash
iptables -D INPUT -s 77.83.39.235 -j DROP
```

---

## Step 3 — Verify Unblocked

```bash
iptables -L INPUT -n | grep IP_TO_UNBLOCK
```

If no output → IP is unblocked ✅

---

## Step 4 — Add to Whitelist

If the IP is legitimate — add it to the whitelist to prevent
future false positives:

```bash
echo "IP_ADDRESS:description" >> /var/ossec/etc/lists/authorized-admin-ips

# Example
echo "172.16.7.100:new_admin_workstation" >> /var/ossec/etc/lists/authorized-admin-ips
```

> ⚠️ Update the whitelist on BOTH servers:
> - Graylog: `/var/ossec/etc/lists/authorized-admin-ips`
> - Manager: `/var/ossec/etc/lists/authorized-admin-ips`

---

## Step 5 — Document the Incident

Register in the incident log (COM-05):

```
Date        : 
IP blocked  : 
Reason      : False positive — legitimate IP
Action taken: Manual unblock + added to whitelist
Resolved by : 
```

---

## Prevention

To avoid false positives — always keep the whitelist up to date:

```
/var/ossec/etc/lists/authorized-admin-ips
→ All admin workstations
→ Graylog server IP
→ Wazuh Manager IP
→ Any scanner or monitoring tool
```

---

## Quick Reference

```bash
# List all blocked IPs
iptables -L INPUT -n | grep DROP

# Unblock specific IP
iptables -D INPUT -s <IP> -j DROP

# Add IP to whitelist
echo "<IP>:<description>" >> /var/ossec/etc/lists/authorized-admin-ips
```

---

*Document maintained as part of Phase 3 — Optimisation & Hardening*  
*Last updated: June 2026*
