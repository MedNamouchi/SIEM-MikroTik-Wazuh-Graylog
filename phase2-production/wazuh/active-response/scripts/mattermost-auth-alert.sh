#!/bin/bash
LOG_FILE="/var/ossec/logs/active-responses.log"
MAIL_TO="amine@ofir.hr , domagoj@ofir.hr"
MATTERMOST_WEBHOOK="https://im.ofir.hr/hooks/4xdzxotfpfdwxdgid9f543drnw"

INPUT=$(timeout 3 cat)
echo "$(date '+%Y-%m-%d %H:%M:%S') - [AR-AUTH] Script triggered" >> "$LOG_FILE"
echo "$(date '+%Y-%m-%d %H:%M:%S') - [AR-AUTH] Raw input: $INPUT" >> "$LOG_FILE"

if ! echo "$INPUT" | jq -e . > /dev/null 2>&1; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') - [AR-AUTH] ERROR: Invalid JSON input" >> "$LOG_FILE"
    exit 1
fi

COMMAND=$(echo "$INPUT" | jq -r '.command // empty')
ALERT=$(echo "$INPUT" | jq -c '.parameters.alert // empty')

echo "$(date '+%Y-%m-%d %H:%M:%S') - [AR-AUTH] Command: $COMMAND" >> "$LOG_FILE"

if [ -z "$COMMAND" ] || [ -z "$ALERT" ]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') - [AR-AUTH] ERROR: Missing command or alert" >> "$LOG_FILE"
    exit 1
fi

if [ "$COMMAND" = "add" ]; then
    RULE_ID=$(echo "$ALERT"    | jq -r '.rule.id          // "unknown"')
    RULE_DESC=$(echo "$ALERT"  | jq -r '.rule.description // "unknown"')
    LEVEL=$(echo "$ALERT"      | jq -r '.rule.level       // "0"')
    SRCIP=$(echo "$ALERT"      | jq -r '.data.srcip       // "N/A"')
    USER=$(echo "$ALERT"       | jq -r '.data.user        // .data.dstuser // "N/A"')
    ROUTER_NAME=$(echo "$ALERT"| jq -r '.data.router_name // "Unknown"')
    APP=$(echo "$ALERT"        | jq -r '.data.app         // "N/A"')
    AGENT=$(echo "$ALERT"      | jq -r '.agent.name       // "unknown"')
    AGENT_IP=$(echo "$ALERT"   | jq -r '.agent.ip         // "unknown"')
    TIMESTAMP=$(echo "$ALERT"  | jq -r '.timestamp        // "N/A"')
    FULL_LOG=$(echo "$ALERT"   | jq -r '.full_log         // "no log"' | head -c 800)
    FIRED=$(echo "$ALERT"      | jq -r '.rule.firedtimes  // "1"')

    # Choisir emoji et type selon login ou logout
    if [ "$RULE_ID" = "100300" ]; then
        EMOJI="✅"
        EVENT="LOGIN"
        SUBJECT="[WAZUH] LOGIN MikroTik - Level ${LEVEL} - Router ${ROUTER_NAME} - User ${USER}"
    else
        EMOJI="🚪"
        EVENT="LOGOUT"
        SUBJECT="[WAZUH] LOGOUT MikroTik - Level ${LEVEL} - Router ${ROUTER_NAME} - User ${USER}"
    fi

    # Mail
    BODY="
========================================================
   WAZUH SECURITY ALERT - MIKROTIK ${EVENT} DETECTED
========================================================
ALERT DETAILS
-------------
Rule ID        : ${RULE_ID}
Description    : ${RULE_DESC}
Severity Level : ${LEVEL}/15
Fired Times    : ${FIRED}
Timestamp      : ${TIMESTAMP}
EVENT INFORMATION
-----------------
Router         : ${ROUTER_NAME}
Source IP      : ${SRCIP}
User           : ${USER}
Access Method  : ${APP}
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
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [AR-AUTH] MAIL SENT - ${EVENT} - ${USER} - Router ${ROUTER_NAME}" >> "$LOG_FILE"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [AR-AUTH] ERROR: Mail sending failed" >> "$LOG_FILE"
        exit 1
    fi

    # Mattermost
    MM_PAYLOAD=$(jq -n \
        --arg text "${EMOJI} **${EVENT} DETECTED** ${EMOJI}
**Router:** ${ROUTER_NAME}
**User:** ${USER}
**Source IP:** ${SRCIP}
**Access Method:** ${APP}
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
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [AR-AUTH] MATTERMOST SENT - ${EVENT} - ${USER} - Router ${ROUTER_NAME}" >> "$LOG_FILE"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [AR-AUTH] ERROR: Mattermost failed" >> "$LOG_FILE"
    fi
fi

if [ "$COMMAND" = "delete" ]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') - [AR-AUTH] DELETE action - no cleanup needed" >> "$LOG_FILE"
fi

exit 0
