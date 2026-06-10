# AR-09 — Agent Behavior When Manager is Unreachable

> **Task:** Test agent behavior when manager is unreachable  
> **Author:** Mohamed Amine Namouchi  
> **Date:** June 2026  
> **Status:** ✅ Complete

---

## Context

What happens to log collection and alerting when the Wazuh Manager
goes down temporarily?

```
Questions tested:
1. Does the agent keep collecting logs?
2. Are events queued and sent when manager comes back?
3. Do active response scripts still fire locally?
```

---

## Test Procedure

```
1. Stop Wazuh Manager
   systemctl stop wazuh-manager

2. Generate events on Graylog server:
   → SSH brute force attempts
   → MikroTik brute force attempts

3. Observe agent behavior

4. Restart Wazuh Manager
   systemctl start wazuh-manager

5. Observe what happens
```

---

## Results

### While Manager is Down

```
Agent behavior:
→ Agent tries to reconnect every 10 seconds
→ Logs continue to be read locally
→ Events buffered in memory

Log output observed:
2026/06/10 12:27:20 wazuh-agentd: WARNING: Unable to connect to any server.
2026/06/10 12:27:20 wazuh-agentd: INFO: Trying to connect to server ([WAZUH_IP]:1514/tcp).
2026/06/10 12:27:30 wazuh-agentd: ERROR: Unable to connect to '[WAZUH_IP]:1514/tcp'
```

### After Manager Restart

```
→ Agent reconnects automatically ✅
→ Buffered events sent to manager ✅
→ Mattermost alerts received ✅
→ No events lost during short interruption ✅
```

### Active Response During Outage

```
→ Active response scripts do NOT fire during outage ❌
→ Blocking and notifications are suspended
→ Resume automatically when manager comes back
```

---

## Conclusion

| Behavior | Result |
|----------|--------|
| Log collection during outage | ✅ Continues locally |
| Events queued in memory | ✅ Yes — sent after reconnect |
| Events lost on short outage | ✅ No data loss |
| Active response during outage | ❌ Suspended |
| Auto-reconnect | ✅ Every 10 seconds |

---

## Impact Assessment

```
Short outage (< 10 minutes):
→ No data loss
→ Alerts delayed but delivered after reconnect
→ Active response suspended during outage

Long outage (> memory buffer):
→ Possible event loss
→ Attacker could act undetected during outage
→ INF-06 (component health monitoring) mitigates this
```

---

## Recommendation

```
→ Monitor Wazuh Manager availability 
→ Keep outages short — restart manager quickly if it goes down
→ Agent health monitoring  alerts when agent disconnects
```

---

*Document maintained as part of Phase 3 — Optimisation & Hardening*  
*Last updated: June 2026*
