# Active Response — MikroTik SIEM Alerting

This folder contains the Wazuh active response scripts used to send
automated alerts (email + Mattermost) when security events are detected
on MikroTik routers.

---

## How Wazuh Active Response Works

```
MikroTik Router
      ↓ log
Wazuh Agent (reads /var/log/mikrotik.log)
      ↓ forwards AES-256
Wazuh Manager
      ↓ matches custom rule (e.g. brute force rule 100302)
      ↓ triggers active response
Active Response Script (runs on the agent)
      ↓                    ↓
  📧 Email Alert    💬 Mattermost Alert
```

The active response mechanism works as follows:

1. Wazuh Manager detects an alert matching a configured rule ID
2. It sends a JSON payload to the agent via the active response channel
3. The agent executes the corresponding script
4. The script parses the JSON, extracts alert fields, and sends notifications

---

## Registration in ossec.conf (Wazuh Manager)

Each script must be registered as a command and linked to a rule on the
**Wazuh Manager** in `/var/ossec/etc/ossec.conf`:

```xml
<!-- Brute Force — real routers (rule 100302) -->
<command>
  <name>mattermost-brute-alert</name>
  <executable>new_script_wazuh_mail_mattermost.sh</executable>
  <timeout_allowed>no</timeout_allowed>
</command>
<active-response>
  <command>mattermost-brute-alert</command>
  <location>local</location>
  <rules_id>100302</rules_id>
</active-response>

<!-- Authentication (login/logout) — rules 100300, 100303 -->
<command>
  <name>mattermost-auth-alert</name>
  <executable>mattermost-auth-alert.sh</executable>
  <timeout_allowed>no</timeout_allowed>
</command>
<active-response>
  <command>mattermost-auth-alert</command>
  <location>local</location>
  <rules_id>100300,100303</rules_id>
</active-response>

<!-- Config Change — rule 100403 -->
<command>
  <name>mattermost-config-alert</name>
  <executable>mattermost-config-alert.sh</executable>
  <timeout_allowed>no</timeout_allowed>
</command>
<active-response>
  <command>mattermost-config-alert</command>
  <location>local</location>
  <rules_id>100403</rules_id>
</active-response>

<!-- Reboot — rules 100400, 100401, 100402 -->
<command>
  <name>mattermost-reboot-alert</name>
  <executable>mattermost-reboot-alert.sh</executable>
  <timeout_allowed>no</timeout_allowed>
</command>
<active-response>
  <command>mattermost-reboot-alert</command>
  <location>local</location>
  <rules_id>100400,100401,100402</rules_id>
</active-response>

<!-- Resource (CPU/RAM) — rules 100500, 100501 -->
<command>
  <name>mattermost-resource-alert</name>
  <executable>mattermost-resource-alert.sh</executable>
  <timeout_allowed>no</timeout_allowed>
</command>
<active-response>
  <command>mattermost-resource-alert</command>
  <location>local</location>
  <rules_id>100500,100501</rules_id>
</active-response>
```

> **Note:** `location: local` means the script runs on the **agent** that
> generated the alert, not on the Wazuh Manager. The scripts must be
> deployed on the agent server (Ubuntu 22.04 — Graylog server).

---

## Scripts Overview

| Script | Triggered by | Detects |
|--------|-------------|---------|
| `new_script_wazuh_mail_mattermost.sh` | Rule `100302` | Brute force on real routers |
| `mattermost-auth-alert.sh` | Rules `100300`, `100303` | Login / Logout |
| `mattermost-config-alert.sh` | Rule `100403` | Config change |
| `mattermost-reboot-alert.sh` | Rules `100400`, `100401`, `100402` | Reboot (conscious / unexpected / crash) |
| `mattermost-resource-alert.sh` | Rules `100500`, `100501` | CPU HIGH / MEMORY HIGH |

---

## Deployment on the Agent

```bash
# Copy scripts to active response directory
sudo cp scripts/*.sh /var/ossec/active-response/bin/

# Set correct permissions on all scripts
sudo chmod 750 /var/ossec/active-response/bin/*.sh
sudo chown root:wazuh /var/ossec/active-response/bin/*.sh

# Install dependencies
sudo apt install mailutils jq -y

# Restart agent to apply
sudo systemctl restart wazuh-agent
```

---

## Alert Examples

### Brute Force (new_script_wazuh_mail_mattermost.sh)
```
Subject: [WAZUH] BRUTE FORCE MikroTik - Level 10 - Router ROUTER_NAME - IP 192.168.1.50

Rule ID     : 100302
Description : MikroTik: Brute force attack - 5+ failures from 192.168.1.50
Router      : ROUTER_NAME
Source IP   : 192.168.1.50
Target User : admin
Access      : winbox
```

### CPU High (mattermost-resource-alert.sh)
```
Subject: [WAZUH] CPU HIGH - Router ROUTER_NAME - 87% usage

Router   : ROUTER_NAME
Resource : CPU
Usage    : 87%
```

### Unexpected Reboot (mattermost-reboot-alert.sh)
```
Subject: [WAZUH] UNEXPECTED REBOOT MikroTik - Level 12 - Router ROUTER_NAME

Router : ROUTER_NAME
Cause  : No user triggered — unplanned reboot
```

### Config Change (mattermost-config-alert.sh)
```
Subject: [WAZUH] CONFIG CHANGE MikroTik - Level 5 - Router ROUTER_NAME - User admin

Router        : ROUTER_NAME
User          : admin
Source IP     : ROUTER_IP
Access Method : winbox
Change        : ip/firewall/filter
```

---

## Key Technical Notes

- **`timeout 3 cat`** — mandatory to avoid deadlock when reading stdin.
  Plain `cat` waits indefinitely for stdin to close and freezes the script.
- **`jq` required** — all scripts use `jq` for JSON parsing.
  Install with `sudo apt install jq -y` on the agent.
- **Independent blocks** — email and Mattermost are always separate blocks.
  If email fails, Mattermost still sends and vice versa.
- **HTTP vs HTTPS for Mattermost** — Mattermost runs on HTTP port 8065
  internally. Use the direct HTTP URL from the agent server, not the HTTPS
  reverse proxy URL which may block internal connections.

---

## Verify Active Response

```bash
# Check scripts are registered (on Wazuh Manager)
sudo /var/ossec/bin/agent_control -L

# Monitor active response logs in real time (on agent)
sudo tail -f /var/ossec/logs/active-responses.log

# Test Mattermost webhook connectivity
curl http://MATTERMOST_IP:8065/hooks/YOUR_WEBHOOK_ID \
  -X POST \
  -H "Content-Type: application/json" \
  -d '{"text":"Test from Wazuh"}'
```
