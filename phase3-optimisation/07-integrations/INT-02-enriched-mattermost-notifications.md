# INT-02 — Enriched Mattermost Notifications

> **Task:** Enrich Mattermost notifications  
> **Author:** Mohamed Amine Namouchi  
> **Date:** June 2026  
> **Status:** ✅ Complete

---

## Context

Before INT-02, Mattermost notifications contained basic info:
```
Router, IP, User, App, Level, Timestamp
```

After INT-02, notifications are enriched with:
```
+ Geolocation   → Country, City, Organization
+ MITRE ATT&CK  → Technique ID + Tactic + Technique name
+ Occurrences   → How many times this IP appeared in alerts.log
+ AR Status     → Is the IP blocked by iptables?
+ Dashboard link → Direct link to Wazuh dashboard
```

---

## Scripts Updated

| Script | Rules | Location |
|--------|-------|----------|
| `new_script_wazuh_mail_mattermost.sh` | 100302 (MikroTik BF) | Graylog agent |
| `mattermost-correlation-alert.sh` | 100800/100801 (Coordinated attack) | Wazuh Manager |

---

## Enrichment Details

### Geolocation (ipapi.co)

```bash
GEO=$(curl -s --max-time 3 "https://ipapi.co/${SRCIP}/json/")
COUNTRY=$(echo "$GEO" | jq -r '.country_name')
CITY=$(echo "$GEO"    | jq -r '.city')
ORG=$(echo "$GEO"     | jq -r '.org')
```

- Free API — no key required
- Returns country, city, organization
- Works for external IPs only
- Internal IPs (RFC1918) return "Unknown" — expected behavior

### MITRE ATT&CK

```bash
MITRE_ID=$(echo "$ALERT"     | jq -r '.rule.mitre.id[0]')
MITRE_TACTIC=$(echo "$ALERT" | jq -r '.rule.mitre.tactic[0]')
MITRE_TECH=$(echo "$ALERT"   | jq -r '.rule.mitre.technique[0]')
```

Extracted directly from the Wazuh alert JSON — no external API needed.

### Occurrences

```bash
OCCURRENCES=$(grep -c "$SRCIP" /var/ossec/logs/alerts/alerts.log)
```

Counts how many times the IP appears in alerts.log — gives context
on whether this is a repeat attacker.

### AR Status

```bash
if iptables -L INPUT -n | grep -q "$SRCIP"; then
    AR_STATUS="🔒 BLOCKED by iptables"
fi
```

Shows if the IP has already been blocked by `iptables-block.sh`.

---

## Notification Example

### Brute Force (Rule 100302)
```
🚨 BRUTE FORCE DETECTED 🚨
Router: OFIR_MAIN_NEW
Source IP: 77.83.39.235 — 📍 Amsterdam, Netherlands (Kprohost LLC)
Target User: admin
Access Method: winbox
Rule: 100302
Level: 10/15
Fired: 5 times | Total occurrences: 23
AR Status: 🔒 BLOCKED by iptables

🎯 MITRE ATT&CK
→ Technique: T1110.001 — Password Guessing
→ Tactic: Credential Access

🔗 Dashboard: https://WAZUH_IP
```

### Coordinated Attack (Rule 100800)
```
🚨🚨🚨 COORDINATED ATTACK DETECTED 🚨🚨🚨
Source IP: 77.83.39.235 — 📍 Amsterdam, Netherlands (Kprohost LLC)
Attack: MikroTik Brute Force + SSH Brute Force from SAME IP
Level: 15/15 ← MAXIMUM
AR Status: Not blocked

🎯 MITRE ATT&CK
→ Technique: T1110 — Brute Force
→ Tactic: Credential Access

🔗 Dashboard: https://WAZUH_IP
```

---

## Validation

Tested on 2026-06-10:
```
✅ Geolocation: Amsterdam, The Netherlands (Kprohost LLC)
✅ MITRE: T1110 — Brute Force — Credential Access
✅ AR Status: Not blocked / 🔒 BLOCKED
✅ Dashboard link working
✅ Occurrences count
```
---

*Document maintained as part of Phase 3 — Optimisation & Hardening*  
*Last updated: June 2026*
