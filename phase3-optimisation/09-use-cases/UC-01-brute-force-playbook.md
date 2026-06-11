# UC-01 — Brute Force Playbook

> **Task:** Write complete playbook for brute-force rule  
> **Author:** Mohamed Amine Namouchi  
> **Date:** June 2026  
> **Status:** ✅ Complete

---

## Trigger

```
Rule 100302 fires:
"MikroTik: Brute force attack - 5+ failures from SOURCE_IP on router ROUTER_NAME"
Level: 10
```

---

## Phase 1 — Identify

```
□ Note the source IP from Mattermost notification
□ Note the router name (OFIR_MAIN_NEW / other)
□ Note the targeted username (dstuser)
□ Note the access method (winbox / ssh / api)
□ Check geolocation in notification → Country + Organization
□ Check total occurrences in notification
```

**Questions to answer:**
```
→ Is this IP internal or external?
→ Is this IP in the whitelist? (if yes → false positive)
→ Has this IP attacked before?
→ Is it targeting a real admin username?
```

---

## Phase 2 — Validate

```
□ Check if IP is whitelisted:
  grep "SOURCE_IP" /var/ossec/etc/lists/authorized-admin-ips

□ Check alert history:
  grep "SOURCE_IP" /var/ossec/logs/alerts/alerts.log | tail -20

□ Check if login succeeded after failures (rule 100300):
  grep "100300" /var/ossec/logs/alerts/alerts.log | grep "SOURCE_IP"

□ Check MikroTik logs directly:
  MikroTik → Log → Filter by src-address=SOURCE_IP

□ Check AR status (auto-blocked?):
  iptables -L INPUT -n | grep "SOURCE_IP"
```

**Decision:**
```
IP whitelisted + internal → FALSE POSITIVE → go to Phase 5
External IP + real attack → REAL INCIDENT → continue to Phase 3
```

---

## Phase 3 — Investigate

```
□ Check VirusTotal (if available):
  → Was IP flagged as malicious?

□ Check if attacker succeeded:
  grep "SOURCE_IP" /var/log/auth.log | grep "Accepted"
  grep "100300" /var/ossec/logs/alerts/alerts.log | grep "SOURCE_IP"

□ Check if attacker is still active:
  tail -f /var/ossec/logs/alerts/alerts.log | grep "SOURCE_IP"

□ Check all routers — is same IP attacking others?
  grep "SOURCE_IP" /var/ossec/logs/alerts/alerts.log | grep "100301\|100302"

□ Check for coordinated attack (rule 100800):
  grep "100800\|100801" /var/ossec/logs/alerts/alerts.log | grep "SOURCE_IP"
```

---

## Phase 4 — Contain

### Automatic (already done by AR)
```
□ iptables auto-block for 10 minutes — verify:
  iptables -L INPUT -n | grep "SOURCE_IP"
```

### Manual if needed
```
□ Extend block on Graylog server:
  iptables -A INPUT -s SOURCE_IP -j DROP

□ Block on MikroTik router:
  MikroTik → IP → Firewall → Filter Rules → Add:
  Chain: input
  Src. Address: SOURCE_IP
  Action: drop
  Comment: Blocked by SOC - brute force

□ If login succeeded → isolate immediately:
  → Change admin passwords on all routers
  → Check for new users: /ip user print
  → Check for new firewall rules: /ip firewall filter print
  → Check for new scripts: /system script print
```

---

## Phase 5 — Close

```
□ Confirm attack stopped (no more alerts from IP)
□ Verify no persistence established:
  → MikroTik: /ip user print
  → MikroTik: /system scheduler print
  → Graylog: cat /etc/passwd
  → Graylog: cat /etc/crontab

□ Document in incident register (COM-05):
  Date       : 
  Incident ID: INC-XXX
  Type       : Brute Force
  Rule ID    : 100302
  Source IP  : 
  Country    : 
  Severity   : 10
  Actions    : IP blocked / login not succeeded / closed
  Resolved By: 
  Status     : Closed

□ Tune if false positive:
  → Add IP to whitelist if legitimate admin
  → echo "IP:description" >> /var/ossec/etc/lists/authorized-admin-ips
```

---

## Timeline

```
T+0min  → Alert received on Mattermost
T+2min  → Triage complete (UC-05)
T+5min  → Validation complete
T+10min → Containment done
T+20min → Investigation complete
T+30min → Incident closed and documented
```

---

## Related Rules

| Rule | Description | Level |
|------|-------------|-------|
| 100301 | Login failure | 5 |
| 100302 | Brute force (5+ failures) | 10 |
| 100300 | Login success | 3 |
| 100700 | Password spraying | 12 |
| 100800 | Coordinated attack | 15 |

---



*Document maintained as part of Phase 3 — Optimisation & Hardening*  
*Last updated: June 2026*
