#!/bin/bash
# =============================================================================
# Wazuh Active Response - Mail + Mattermost Alert for MikroTik Brute Force
# Real routers (ROUTER_NAME format) - Rule 100302
# =============================================================================

LOG_FILE="/var/ossec/logs/active-responses.log"
MAIL_TO="amine@ofir.hr , ADMIN_USER@ofir.hr"
MATTERMOST_WEBHOOK="https://MATTERMOST_WEBHOOK"

# -----------------------------
# READ INPUT (Wazuh 4.x format)
# -----------------------------
INPUT=$(timeout 3 cat)
echo "$(date '+%Y-%m-%d %H:%M:%S') - [AR] Script triggered" >> "$LOG_FILE"
echo "$(date '+%Y-%m-%d %H:%M:%S') - [AR] Raw input: $INPUT" >> "$LOG_FILE"

if ! echo "$INPUT" | jq -e . > /dev/null 2>&1; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') - [AR] ERROR: Invalid JSON input" >> "$LOG_FILE"
    exit 1
fi

# -----------------------------
# PARSE COMMAND AND ALERT
# -----------------------------
COMMAND=$(echo "$INPUT" | jq -r '.command // empty')
ALERT=$(echo "$INPUT" | jq -c '.parameters.alert // empty')

echo "$(date '+%Y-%m-%d %H:%M:%S') - [AR] Command: $COMMAND" >> "$LOG_FILE"

if [ -z "$COMMAND" ] || [ -z "$ALERT" ]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') - [AR] ERROR: Missing command or alert" >> "$LOG_FILE"
    exit 1
fi

# -----------------------------
# ADD ACTION
# -----------------------------
if [ "$COMMAND" = "add" ]; then

    RULE_ID=$(echo "$ALERT"    | jq -r '.rule.id          // "unknown"')
    RULE_DESC=$(echo "$ALERT"  | jq -r '.rule.description // "unknown"')
    LEVEL=$(echo "$ALERT"      | jq -r '.rule.level       // "0"')
    SRCIP=$(echo "$ALERT"      | jq -r '.data.srcip       // "N/A"')
    DSTUSER=$(echo "$ALERT"    | jq -r '.data.dstuser     // "N/A"')
    ROUTER_NAME=$(echo "$ALERT"| jq -r '.data.router_name // "Unknown"')
    APP=$(echo "$ALERT"        | jq -r '.data.app         // "N/A"')
    AGENT=$(echo "$ALERT"      | jq -r '.agent.name       // "unknown"')
    AGENT_IP=$(echo "$ALERT"   | jq -r '.agent.ip         // "unknown"')
    TIMESTAMP=$(echo "$ALERT"  | jq -r '.timestamp        // "N/A"')
    FULL_LOG=$(echo "$ALERT"   | jq -r '.full_log         // "no log"' | head -c 800)
    FIRED=$(echo "$ALERT"      | jq -r '.rule.firedtimes  // "1"')

    # Mail
    SUBJECT="[WAZUH] BRUTE FORCE MikroTik - Level ${LEVEL} - Router ${ROUTER_NAME} - IP ${SRCIP}"

    BODY="
========================================================
   WAZUH SECURITY ALERT - MIKROTIK BRUTE FORCE DETECTED
========================================================

ALERT DETAILS
-------------
Rule ID        : ${RULE_ID}
Description    : ${RULE_DESC}
Severity Level : ${LEVEL}/15
Fired Times    : ${FIRED}
Timestamp      : ${TIMESTAMP}

ATTACK INFORMATION
------------------
Router         : ${ROUTER_NAME}
Source IP      : ${SRCIP}
Target User    : ${DSTUSER}
Access Method  : ${APP}

WAZUH AGENT
-----------
Agent Name     : ${AGENT}
Agent IP       : ${AGENT_IP}

RECOMMENDED ACTIONS
-------------------
[1] Block IP immediately : iptables -A INPUT -s ${SRCIP} -j DROP
[2] Check router logs    : MikroTik -> Log -> Filter by IP ${SRCIP}
[3] Verify user account  : Check if '${DSTUSER}' is still active
[4] Restrict access      : Limit Winbox/SSH to trusted IPs only

FULL LOG (extract)
------------------
${FULL_LOG}

========================================================
This alert was generated automatically by Wazuh SIEM.
Do not reply to this email.
========================================================
"

    if echo "$BODY" | mail -s "$SUBJECT" "$MAIL_TO" 2>> "$LOG_FILE"; then
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [AR] MAIL SENT - Rule ${RULE_ID} - Router ${ROUTER_NAME} - IP ${SRCIP}" >> "$LOG_FILE"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [AR] ERROR: Mail sending failed" >> "$LOG_FILE"
        exit 1
    fi

    # Mattermost
    MM_PAYLOAD=$(jq -n \
        --arg text "🚨 **BRUTE FORCE DETECTED** 🚨
**Router:** ${ROUTER_NAME}
**Source IP:** ${SRCIP}
**Target User:** ${DSTUSER}
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
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [AR] MATTERMOST SENT - Router ${ROUTER_NAME} - IP ${SRCIP}" >> "$LOG_FILE"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [AR] ERROR: Mattermost failed" >> "$LOG_FILE"
    fi

fi

# -----------------------------
# DELETE ACTION
# -----------------------------
if [ "$COMMAND" = "delete" ]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') - [AR] DELETE action - no cleanup needed" >> "$LOG_FILE"
fi

exit 0
