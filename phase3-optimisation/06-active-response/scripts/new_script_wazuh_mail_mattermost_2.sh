#!/bin/bash
# =============================================================================
# Wazuh Active Response - Mail + Mattermost Alert for MikroTik Brute Force
# Real routers (OFIR_MAIN_NEW format) - Rule 100302
# INT-02: Enriched with MITRE, country, occurrences, AR status, dashboard link
# =============================================================================

LOG_FILE="/var/ossec/logs/active-responses.log"
MAIL_TO="amine@ofir.hr , domagoj@ofir.hr"
MATTERMOST_WEBHOOK="https://MATTERMOST_WEBHOOK"
WAZUH_DASHBOARD="https://WAZUH_DASHBOARD"
ALERTS_LOG="/var/ossec/logs/alerts/alerts.log"

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

    RULE_ID=$(echo "$ALERT"      | jq -r '.rule.id               // "unknown"')
    RULE_DESC=$(echo "$ALERT"    | jq -r '.rule.description      // "unknown"')
    LEVEL=$(echo "$ALERT"        | jq -r '.rule.level            // "0"')
    SRCIP=$(echo "$ALERT"        | jq -r '.data.srcip            // "N/A"')
    DSTUSER=$(echo "$ALERT"      | jq -r '.data.dstuser          // "N/A"')
    ROUTER_NAME=$(echo "$ALERT"  | jq -r '.data.router_name      // "Unknown"')
    APP=$(echo "$ALERT"          | jq -r '.data.app              // "N/A"')
    AGENT=$(echo "$ALERT"        | jq -r '.agent.name            // "unknown"')
    AGENT_IP=$(echo "$ALERT"     | jq -r '.agent.ip              // "unknown"')
    TIMESTAMP=$(echo "$ALERT"    | jq -r '.timestamp             // "N/A"')
    FULL_LOG=$(echo "$ALERT"     | jq -r '.full_log              // "no log"' | head -c 800)
    FIRED=$(echo "$ALERT"        | jq -r '.rule.firedtimes       // "1"')
    MITRE_ID=$(echo "$ALERT"     | jq -r '.rule.mitre.id[0]      // "N/A"')
    MITRE_TACTIC=$(echo "$ALERT" | jq -r '.rule.mitre.tactic[0]  // "N/A"')
    MITRE_TECH=$(echo "$ALERT"   | jq -r '.rule.mitre.technique[0] // "N/A"')

    # -----------------------------
    # ENRICHMENT 1 — COUNTRY (ipapi.co — no key needed)
    # -----------------------------
    COUNTRY="Unknown"
    CITY="Unknown"
    ORG="Unknown"
    if [ "$SRCIP" != "N/A" ] && [ "$SRCIP" != "unknown" ]; then
        GEO=$(curl -s --max-time 3 "https://ipapi.co/${SRCIP}/json/" 2>/dev/null)
        if echo "$GEO" | jq -e . > /dev/null 2>&1; then
            COUNTRY=$(echo "$GEO" | jq -r '.country_name // "Unknown"')
            CITY=$(echo "$GEO"    | jq -r '.city         // "Unknown"')
            ORG=$(echo "$GEO"     | jq -r '.org          // "Unknown"')
        fi
    fi
    echo "$(date '+%Y-%m-%d %H:%M:%S') - [AR] GEO: ${SRCIP} → ${CITY}, ${COUNTRY} (${ORG})" >> "$LOG_FILE"

    # -----------------------------
    # ENRICHMENT 2 — OCCURRENCES (last 24h from alerts.log)
    # -----------------------------
    OCCURRENCES=0
    if [ -f "$ALERTS_LOG" ] && [ "$SRCIP" != "N/A" ]; then
        OCCURRENCES=$(grep -c "$SRCIP" "$ALERTS_LOG" 2>/dev/null || echo "0")
    fi

    # -----------------------------
    # ENRICHMENT 3 — AR STATUS (is IP blocked by iptables?)
    # -----------------------------
    AR_STATUS="Not blocked"
    if iptables -L INPUT -n 2>/dev/null | grep -q "$SRCIP"; then
        AR_STATUS="🔒 BLOCKED by iptables"
    fi

    # -----------------------------
    # ENRICHMENT 4 — DASHBOARD LINK
    # -----------------------------
    DASHBOARD_LINK="${WAZUH_DASHBOARD}/app/security-alerts"

    # Mail
    SUBJECT="[WAZUH] BRUTE FORCE MikroTik - Level ${LEVEL} - Router ${ROUTER_NAME} - IP ${SRCIP} (${COUNTRY})"

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
Dashboard      : ${DASHBOARD_LINK}

ATTACK INFORMATION
------------------
Router         : ${ROUTER_NAME}
Source IP      : ${SRCIP}
Target User    : ${DSTUSER}
Access Method  : ${APP}
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
**Source IP:** ${SRCIP} — 📍 ${CITY}, ${COUNTRY} (${ORG})
**Target User:** ${DSTUSER}
**Access Method:** ${APP}
**Rule:** ${RULE_ID} - ${RULE_DESC}
**Level:** ${LEVEL}/15
**Fired:** ${FIRED} times | **Total occurrences:** ${OCCURRENCES}
**AR Status:** ${AR_STATUS}
**Timestamp:** ${TIMESTAMP}
**Agent:** ${AGENT} (${AGENT_IP})

🎯 **MITRE ATT&CK**
→ Technique: ${MITRE_ID} — ${MITRE_TECH}
→ Tactic: ${MITRE_TACTIC}

🔗 **Dashboard:** ${DASHBOARD_LINK}" \
        '{text: $text}')

    if curl -s -o /dev/null -w "%{http_code}" \
        -X POST \
        -H "Content-Type: application/json" \
        -d "$MM_PAYLOAD" \
        "$MATTERMOST_WEBHOOK" | grep -q "200"; then
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [AR] MATTERMOST SENT - Router ${ROUTER_NAME} - IP ${SRCIP} - ${COUNTRY}" >> "$LOG_FILE"
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
