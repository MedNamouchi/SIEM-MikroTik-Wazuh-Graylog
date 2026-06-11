#!/bin/bash
# =============================================================================
# Wazuh Active Response - Mail + Mattermost Alert for Coordinated Attack
# Multi-source correlation: MikroTik brute force + SSH brute force same IP
# Rules 100800, 100801 — Level 15 CRITICAL
# INT-02: Enriched with MITRE, country, occurrences, AR status, dashboard link
# =============================================================================

LOG_FILE="/var/ossec/logs/active-responses.log"
MAIL_TO="amine@ofir.hr , domagoj@ofir.hr"
MATTERMOST_WEBHOOK="https://MATTERMOST_WEBHOOK"
WAZUH_DASHBOARD="https://WAZUH_DASHBOARD"
ALERTS_LOG="/var/ossec/logs/alerts/alerts.log"

INPUT=$(timeout 3 cat)
echo "$(date '+%Y-%m-%d %H:%M:%S') - [AR-CORRELATION] Script triggered" >> "$LOG_FILE"

if ! echo "$INPUT" | jq -e . > /dev/null 2>&1; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') - [AR-CORRELATION] ERROR: Invalid JSON input" >> "$LOG_FILE"
    exit 1
fi

COMMAND=$(echo "$INPUT" | jq -r '.command // empty')
ALERT=$(echo "$INPUT" | jq -c '.parameters.alert // empty')

if [ -z "$COMMAND" ] || [ -z "$ALERT" ]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') - [AR-CORRELATION] ERROR: Missing command or alert" >> "$LOG_FILE"
    exit 1
fi

if [ "$COMMAND" = "add" ]; then

    RULE_ID=$(echo "$ALERT"      | jq -r '.rule.id                // "unknown"')
    RULE_DESC=$(echo "$ALERT"    | jq -r '.rule.description       // "unknown"')
    LEVEL=$(echo "$ALERT"        | jq -r '.rule.level             // "0"')
    SRCIP=$(echo "$ALERT"        | jq -r '.data.srcip             // "N/A"')
    AGENT=$(echo "$ALERT"        | jq -r '.agent.name             // "unknown"')
    AGENT_IP=$(echo "$ALERT"     | jq -r '.agent.ip               // "unknown"')
    TIMESTAMP=$(echo "$ALERT"    | jq -r '.timestamp              // "N/A"')
    FULL_LOG=$(echo "$ALERT"     | jq -r '.full_log               // "no log"' | head -c 800)
    FIRED=$(echo "$ALERT"        | jq -r '.rule.firedtimes        // "1"')
    MITRE_ID=$(echo "$ALERT"     | jq -r '.rule.mitre.id[0]       // "N/A"')
    MITRE_TACTIC=$(echo "$ALERT" | jq -r '.rule.mitre.tactic[0]   // "N/A"')
    MITRE_TECH=$(echo "$ALERT"   | jq -r '.rule.mitre.technique[0] // "N/A"')

    # ENRICHMENT 1 — COUNTRY
    COUNTRY="Unknown"; CITY="Unknown"; ORG="Unknown"
    if [ "$SRCIP" != "N/A" ]; then
        GEO=$(curl -s --max-time 3 "https://ipapi.co/${SRCIP}/json/" 2>/dev/null)
        if echo "$GEO" | jq -e . > /dev/null 2>&1; then
            COUNTRY=$(echo "$GEO" | jq -r '.country_name // "Unknown"')
            CITY=$(echo "$GEO"    | jq -r '.city         // "Unknown"')
            ORG=$(echo "$GEO"     | jq -r '.org          // "Unknown"')
        fi
    fi

    # ENRICHMENT 2 — OCCURRENCES
    OCCURRENCES=0
    if [ -f "$ALERTS_LOG" ] && [ "$SRCIP" != "N/A" ]; then
        OCCURRENCES=$(grep -c "$SRCIP" "$ALERTS_LOG" 2>/dev/null || echo "0")
    fi

    # ENRICHMENT 3 — AR STATUS
    AR_STATUS="Not blocked"
    if iptables -L INPUT -n 2>/dev/null | grep -q "$SRCIP"; then
        AR_STATUS="🔒 BLOCKED by iptables"
    fi

    SUBJECT="🚨 [WAZUH] CRITICAL - COORDINATED ATTACK - Level ${LEVEL}/15 - IP ${SRCIP} (${COUNTRY})"

    BODY="
========================================================
   🚨 WAZUH CRITICAL ALERT - COORDINATED ATTACK DETECTED
========================================================

ALERT DETAILS
-------------
Rule ID        : ${RULE_ID}
Description    : ${RULE_DESC}
Severity Level : ${LEVEL}/15  ← MAXIMUM
Fired Times    : ${FIRED}
Timestamp      : ${TIMESTAMP}
Dashboard      : ${WAZUH_DASHBOARD}

ATTACK INFORMATION
------------------
Source IP      : ${SRCIP}
Attack Vector  : MikroTik Brute Force + SSH Brute Force
AR Status      : ${AR_STATUS}
Occurrences    : ${OCCURRENCES} times in alerts.log

GEOLOCATION
-----------
Country        : ${COUNTRY}
City           : ${CITY}
Organization   : ${ORG}

MITRE ATT&CK
------------
Technique ID   : ${MITRE_ID}
Tactic         : ${MITRE_TACTIC}
Technique      : ${MITRE_TECH}

WAZUH AGENT
-----------
Agent Name     : ${AGENT}
Agent IP       : ${AGENT_IP}

⚠️ IMMEDIATE ACTIONS REQUIRED
------------------------------
[1] Block IP on all routers: MikroTik → Firewall → DROP src=${SRCIP}
[2] Block IP on Graylog: iptables -A INPUT -s ${SRCIP} -j DROP
[3] Check logins: grep "${SRCIP}" /var/log/auth.log
[4] Verify no persistence: /etc/passwd, /etc/crontab, ~/.ssh/authorized_keys

FULL LOG
--------
${FULL_LOG}

========================================================
Wazuh SIEM — CRITICAL LEVEL — Immediate action required.
========================================================
"

    if echo "$BODY" | mail -s "$SUBJECT" "$MAIL_TO" 2>> "$LOG_FILE"; then
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [AR-CORRELATION] MAIL SENT - IP ${SRCIP} - ${COUNTRY}" >> "$LOG_FILE"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [AR-CORRELATION] ERROR: Mail failed" >> "$LOG_FILE"
        exit 1
    fi

    MM_PAYLOAD=$(jq -n \
        --arg text "🚨🚨🚨 **COORDINATED ATTACK DETECTED** 🚨🚨🚨
**Source IP:** ${SRCIP} — 📍 ${CITY}, ${COUNTRY} (${ORG})
**Attack:** MikroTik Brute Force + SSH Brute Force from SAME IP
**Rule:** ${RULE_ID} - ${RULE_DESC}
**Level:** ${LEVEL}/15 ← MAXIMUM
**Fired:** ${FIRED} times | **Total occurrences:** ${OCCURRENCES}
**AR Status:** ${AR_STATUS}
**Timestamp:** ${TIMESTAMP}
**Agent:** ${AGENT} (${AGENT_IP})

🎯 **MITRE ATT&CK**
→ Technique: ${MITRE_ID} — ${MITRE_TECH}
→ Tactic: ${MITRE_TACTIC}

⚠️ **IMMEDIATE ACTION REQUIRED:**
→ Block IP ${SRCIP} on all routers
→ Block IP ${SRCIP} on Graylog server
→ Check for successful logins
→ Verify no persistence established

🔗 **Dashboard:** ${WAZUH_DASHBOARD}" \
        '{text: $text}')

    curl -s -o /dev/null -w "%{http_code}" \
        -X POST -H "Content-Type: application/json" \
        -d "$MM_PAYLOAD" "$MATTERMOST_WEBHOOK" | grep -q "200" && \
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [AR-CORRELATION] MATTERMOST SENT - IP ${SRCIP} - ${COUNTRY}" >> "$LOG_FILE"

fi

if [ "$COMMAND" = "delete" ]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') - [AR-CORRELATION] DELETE action" >> "$LOG_FILE"
fi

exit 0
