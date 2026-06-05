#!/bin/bash
# =============================================================================
# Wazuh Active Response - Mail + Mattermost Alert for Agent Disconnection
# Triggers when a Wazuh agent goes offline - Rule 100600
# =============================================================================

LOG_FILE="/var/ossec/logs/active-responses.log"
MAIL_TO="amine@ofir.hr , domagoj@ofir.hr"
MATTERMOST_WEBHOOK="https://MATTERMOST_WEBHOOK"

# -----------------------------
# READ INPUT (Wazuh 4.x format)
# -----------------------------
INPUT=$(timeout 3 cat)
echo "$(date '+%Y-%m-%d %H:%M:%S') - [AR-AGENT] Script triggered" >> "$LOG_FILE"
echo "$(date '+%Y-%m-%d %H:%M:%S') - [AR-AGENT] Raw input: $INPUT" >> "$LOG_FILE"

if ! echo "$INPUT" | jq -e . > /dev/null 2>&1; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') - [AR-AGENT] ERROR: Invalid JSON input" >> "$LOG_FILE"
    exit 1
fi

# -----------------------------
# PARSE COMMAND AND ALERT
# -----------------------------
COMMAND=$(echo "$INPUT" | jq -r '.command // empty')
ALERT=$(echo "$INPUT" | jq -c '.parameters.alert // empty')

echo "$(date '+%Y-%m-%d %H:%M:%S') - [AR-AGENT] Command: $COMMAND" >> "$LOG_FILE"

if [ -z "$COMMAND" ] || [ -z "$ALERT" ]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') - [AR-AGENT] ERROR: Missing command or alert" >> "$LOG_FILE"
    exit 1
fi

# -----------------------------
# ADD ACTION
# -----------------------------
if [ "$COMMAND" = "add" ]; then

    RULE_ID=$(echo "$ALERT"    | jq -r '.rule.id          // "unknown"')
    RULE_DESC=$(echo "$ALERT"  | jq -r '.rule.description // "unknown"')
    LEVEL=$(echo "$ALERT"      | jq -r '.rule.level       // "0"')
    AGENT=$(echo "$ALERT"      | jq -r '.agent.name       // "unknown"')
    AGENT_ID=$(echo "$ALERT"   | jq -r '.agent.id         // "unknown"')
    AGENT_IP=$(echo "$ALERT"   | jq -r '.agent.ip         // "unknown"')
    TIMESTAMP=$(echo "$ALERT"  | jq -r '.timestamp        // "N/A"')
    FIRED=$(echo "$ALERT"      | jq -r '.rule.firedtimes  // "1"')
    FULL_LOG=$(echo "$ALERT"   | jq -r '.full_log         // "no log"' | head -c 800)

    # Mail
    SUBJECT="[WAZUH] ⚠️ AGENT DOWN - ${AGENT} (${AGENT_IP}) - Level ${LEVEL}"

    BODY="
========================================================
   WAZUH ALERT - AGENT DISCONNECTED
========================================================

ALERT DETAILS
-------------
Rule ID        : ${RULE_ID}
Description    : ${RULE_DESC}
Severity Level : ${LEVEL}/15
Fired Times    : ${FIRED}
Timestamp      : ${TIMESTAMP}

AGENT INFORMATION
-----------------
Agent Name     : ${AGENT}
Agent ID       : ${AGENT_ID}
Agent IP       : ${AGENT_IP}

IMPACT ASSESSMENT
-----------------
If agent is 'graylog':
  -> MikroTik logs are NO LONGER forwarded to Wazuh
  -> Brute force detection is DISABLED
  -> Active response is DISABLED
  -> Check Graylog server immediately

If agent is 'punica.ofir.hr':
  -> System monitoring for punica is DOWN
  -> Check server status immediately

RECOMMENDED ACTIONS
-------------------
[1] Check server status  : ping ${AGENT_IP}
[2] Check agent service  : systemctl status wazuh-agent
[3] Restart if needed    : systemctl restart wazuh-agent
[4] Check logs           : tail -50 /var/ossec/logs/ossec.log

FULL LOG (extract)
------------------
${FULL_LOG}

========================================================
This alert was generated automatically by Wazuh SIEM.
Do not reply to this email.
========================================================
"

    if echo "$BODY" | mail -s "$SUBJECT" "$MAIL_TO" 2>> "$LOG_FILE"; then
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [AR-AGENT] MAIL SENT - Agent ${AGENT} (${AGENT_IP}) disconnected" >> "$LOG_FILE"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [AR-AGENT] ERROR: Mail sending failed" >> "$LOG_FILE"
        exit 1
    fi

    # Mattermost
    MM_PAYLOAD=$(jq -n \
        --arg text "⚠️ **AGENT DISCONNECTED** ⚠️
**Agent Name:** ${AGENT}
**Agent ID:** ${AGENT_ID}
**Agent IP:** ${AGENT_IP}
**Rule:** ${RULE_ID} - ${RULE_DESC}
**Level:** ${LEVEL}/15
**Fired:** ${FIRED} times
**Timestamp:** ${TIMESTAMP}

⚠️ If this is the **graylog** agent:
→ MikroTik log forwarding is DOWN
→ Brute force detection is DISABLED
→ Check Graylog server immediately !" \
        '{text: $text}')

    if curl -s -o /dev/null -w "%{http_code}" \
        -X POST \
        -H "Content-Type: application/json" \
        -d "$MM_PAYLOAD" \
        "$MATTERMOST_WEBHOOK" | grep -q "200"; then
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [AR-AGENT] MATTERMOST SENT - Agent ${AGENT} (${AGENT_IP}) disconnected" >> "$LOG_FILE"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [AR-AGENT] ERROR: Mattermost failed" >> "$LOG_FILE"
    fi

fi

# -----------------------------
# DELETE ACTION
# -----------------------------
if [ "$COMMAND" = "delete" ]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') - [AR-AGENT] DELETE action - no cleanup needed" >> "$LOG_FILE"
fi

exit 0
