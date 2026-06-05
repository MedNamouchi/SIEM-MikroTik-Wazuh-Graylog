# LOG-07 — Agent Health Monitoring

> **Task:** Implement agent health monitoring — alert when agent disconnected  
> **Author:** Mohamed Amine Namouchi  
> **Date:** June 5, 2026  
> **Status:** ✅ Complete

---

## Context

If the Wazuh agent on the Graylog server goes down:

```
→ MikroTik logs stop being forwarded
→ Brute force detection is disabled
→ Active response scripts stop working
→ No one is notified — silent failure
```

LOG-07 ensures that any agent disconnection triggers
an immediate Mattermost + email notification.

---

## Key Technical Note — Agent Stopped vs Disconnected

There are two different scenarios:

| Event | Trigger | Wazuh Rule |
|-------|---------|-----------|
| `Agent stopped` | `systemctl stop wazuh-agent` — graceful shutdown | Rule 506 |
| `Agent disconnected` | Network loss, crash, no keepalive after 15 min | Rule 504 |

Both scenarios are covered by our custom rules 100600 and 100601.

---

## Important Note — Script Location

The active response script runs on the **Wazuh Manager** (`location: server`),
NOT on the agent.

```
Why: If the Graylog agent is down, it cannot receive
     and execute the notification script.
     The Manager must send the notification itself.
```

The script must be deployed on **both** the Graylog agent
AND the Wazuh Manager.

---

## Configuration

### 1. Custom Rules — local_rules.xml (Manager)

```xml
<!-- Agent monitoring — Phase 3 LOG-07 -->
<group name="ossec,agent_disconnected,">

  <!-- Agent stopped (graceful shutdown) — Rule 506 -->
  <rule id="100600" level="10">
    <if_sid>506</if_sid>
    <description>Wazuh agent stopped — pipeline may be affected</description>
    <mitre>
      <id>T1562.001</id>
    </mitre>
  </rule>

  <!-- Agent disconnected (crash or network loss) — Rule 504 -->
  <rule id="100601" level="12">
    <if_sid>504</if_sid>
    <description>Wazuh agent disconnected unexpectedly — pipeline may be affected</description>
    <mitre>
      <id>T1562.001</id>
    </mitre>
  </rule>

</group>
```

### 2. Command + Active Response — ossec.conf (Manager)

```xml
<!-- Agent disconnected — Phase 3 LOG-07 -->
<command>
  <name>mattermost-agent-down</name>
  <executable>mattermost-agent-down.sh</executable>
  <timeout_allowed>no</timeout_allowed>
</command>
<active-response>
  <command>mattermost-agent-down</command>
  <location>server</location>
  <rules_id>100600,100601</rules_id>
</active-response>
```

### 3. Global Config — ossec.conf (Manager)

```xml
<agents_disconnection_time>15m</agents_disconnection_time>
<agents_disconnection_alert_time>1m</agents_disconnection_alert_time>
```

### 4. Script Deployment

```bash
# On Wazuh Manager AND Graylog Agent
cp mattermost-agent-down.sh /var/ossec/active-response/bin/
chmod 750 /var/ossec/active-response/bin/mattermost-agent-down.sh
chown root:wazuh /var/ossec/active-response/bin/mattermost-agent-down.sh
```

---

## Notification Example

```
⚠️ AGENT DISCONNECTED ⚠️

Agent Name : graylog
Agent ID   : 001
Agent IP   : GRAYLOG_IP
Rule       : 100600 - Wazuh agent stopped — pipeline may be affected
Level      : 10/15
Fired      : 1 times
Timestamp  : 2026-06-05T15:22:55

⚠️ If this is the graylog agent:
→ MikroTik log forwarding is DOWN
→ Brute force detection is DISABLED
→ Check Graylog server immediately !
```

---

## Validation

Confirmed working on 2026-06-05:

```
Rule: 100600 (level 10) -> 'Wazuh agent stopped — pipeline may be affected'
ossec: Agent stopped: 'graylog->any'
→ Mattermost notification received ✅
→ Email notification received ✅
```

---



*Document maintained as part of Phase 3 — Optimisation & Hardening*  
*Last updated: June 2026*
