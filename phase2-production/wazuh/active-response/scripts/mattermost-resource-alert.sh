#!/bin/bash
LOG_FILE="/var/ossec/logs/active-responses.log"
MAIL_TO="amine@ofir.hr , ADMIN_USER@ofir.hr"
MATTERMOST_WEBHOOK="https://MATTERMOST_WEBHOOK"

INPUT=$(timeout 3 cat)
echo "$(date '+%Y-%m-%d %H:%M:%S') - [AR-RESOURCE] Script triggered" >> "$LOG_FILE"
echo "$(date '+%Y-%m-%d %H:%M:%S') - [AR-RESOURCE] Raw input: $INPUT" >> "$LOG_FILE"

if ! echo "$INPUT" | jq -e . > /dev/null 2>&1; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') - [AR-RESOURCE] ERROR: Invalid JSON input" >> "$LOG_FILE"
    exit 1
fi

COMMAND=$(echo "$INPUT" | jq -r '.command // empty')
ALERT=$(echo "$INPUT" | jq -c '.parameters.alert // empty')

echo "$(date '+%Y-%m-%d %H:%M:%S') - [AR-RESOURCE] Command: $COMMAND" >> "$LOG_FILE"

if [ -z "$COMMAND" ] || [ -z "$ALERT" ]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') - [AR-RESOURCE] ERROR: Missing command or alert" >> "$LOG_FILE"
    exit 1
fi

if [ "$COMMAND" = "add" ]; then
    RULE_ID=$(echo "$ALERT"       | jq -r '.rule.id          // "unknown"')
    RULE_DESC=$(echo "$ALERT"     | jq -r '.rule.description // "unknown"')
    LEVEL=$(echo "$ALERT"         | jq -r '.rule.level       // "0"')
    ROUTER_NAME=$(echo "$ALERT"   | jq -r '.data.router_name // "Unknown"')
    RESOURCE_TYPE=$(echo "$ALERT" | jq -r '.data.resource_type  // "N/A"')
    RESOURCE_VAL=$(echo "$ALERT"  | jq -r '.data.resource_value // "N/A"')
    AGENT=$(echo "$ALERT"         | jq -r '.agent.name       // "unknown"')
    AGENT_IP=$(echo "$ALERT"      | jq -r '.agent.ip         // "unknown"')
    TIMESTAMP=$(echo "$ALERT"     | jq -r '.timestamp        // "N/A"')
    FIRED=$(echo "$ALERT"         | jq -r '.rule.firedtimes  // "1"')
    FULL_LOG=$(echo "$ALERT"      | jq -r '.full_log         // "no log"' | head -c 800)

    if [ "$RESOURCE_TYPE" = "CPU" ]; then
        EMOJI="🔥"
    else
        EMOJI="💾"
    fi

    SUBJECT="[WAZUH] ${RESOURCE_TYPE} HIGH - Router ${ROUTER_NAME} - ${RESOURCE_VAL}% usage"
    BODY="
========================================================
   WAZUH ALERT - MIKROTIK ${RESOURCE_TYPE} HIGH
========================================================
ALERT DETAILS
-------------
Rule ID        : ${RULE_ID}
Description    : ${RULE_DESC}
Severity Level : ${LEVEL}/15
Fired Times    : ${FIRED}
Timestamp      : ${TIMESTAMP}
RESOURCE INFORMATION
--------------------
Router         : ${ROUTER_NAME}
Resource       : ${RESOURCE_TYPE}
Usage          : ${RESOURCE_VAL}%
WAZUH AGENT
-----------
Agent Name     : ${AGENT}
Agent IP       : ${AGENT_IP}
FULL LOG (extract)
------------------
${FULL_LOG}
========================================================
This alert was generated automatically by Wazuh SIEM.
Do not reply to this email.
========================================================
"
    if echo "$BODY" | mail -s "$SUBJECT" "$MAIL_TO" 2>> "$LOG_FILE"; then
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [AR-RESOURCE] MAIL SENT - ${RESOURCE_TYPE} HIGH - Router ${ROUTER_NAME} - ${RESOURCE_VAL}%" >> "$LOG_FILE"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [AR-RESOURCE] ERROR: Mail sending failed" >> "$LOG_FILE"
        exit 1
    fi

    MM_PAYLOAD=$(jq -n \
        --arg text "${EMOJI} **${RESOURCE_TYPE} HIGH DETECTED** ${EMOJI}
**Router:** ${ROUTER_NAME}
**${RESOURCE_TYPE} Usage:** ${RESOURCE_VAL}%
**Rule:** ${RULE_ID} - ${RULE_DESC}
**Level:** ${LEVEL}/15
**Fired:** ${FIRED} times
**Timestamp:** ${TIMESTAMP}
**Agent:** ${AGENT} (${AGENT_IP})" \
        '{text: $text}')

    if curl -s -o /dev/null -w "%{http_code}" \
        -X POST \
        -H "Content-Type: application/json" \
        -d "$MM_PAYLOAD" \
        "$MATTERMOST_WEBHOOK" | grep -q "200"; then
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [AR-RESOURCE] MATTERMOST SENT - ${RESOURCE_TYPE} HIGH - Router ${ROUTER_NAME}" >> "$LOG_FILE"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [AR-RESOURCE] ERROR: Mattermost failed" >> "$LOG_FILE"
    fi
fi

if [ "$COMMAND" = "delete" ]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') - [AR-RESOURCE] DELETE action - no cleanup needed" >> "$LOG_FILE"
fi

exit 0
