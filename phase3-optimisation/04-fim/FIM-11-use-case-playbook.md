# FIM-11 — File Integrity Monitoring Use Case & Playbook

> **Task:** FIM-11 — Create FIM use case with playbook  
> **Author:** Mohamed Amine Namouchi  
> **Date:** June 3, 2026  
> **Status:** ✅ Complete

---

## Use Case Definition

| Field | Value |
|-------|-------|
| **Name** | Critical File Modified — Unauthorized Change |
| **Data Source** | Wazuh FIM (syscheck) |
| **MITRE Tactic** | Defense Evasion (TA0005) / Persistence (TA0003) |
| **MITRE Techniques** | T1070 (Log clearing), T1053 (Scheduled tasks), T1543 (Services), T1098 (Account manipulation) |
| **Severity** | High → Critical (depends on path) |
| **Analysts** | Mohamed Amine Namouchi  |
| **Notification** | Mattermost + Email |

---

## Severity by Path

| Path Modified | Severity | Reason |
|--------------|----------|--------|
| `/var/ossec/etc/ossec.conf` | 🔴 Critical | Entire detection can be disabled |
| `/var/ossec/etc/decoders/` | 🔴 Critical | All rule matching stops silently |
| `/var/ossec/etc/rules/` | 🔴 Critical | All alerts stop firing silently |
| `/var/ossec/active-response/bin/` | 🔴 Critical | Automated defenses compromised |
| `/etc/graylog/` | 🔴 Critical | Log pipeline can be redirected |
| `/etc/rsyslog.conf` | 🔴 Critical | MikroTik logs stop silently |
| `/etc/sudoers` | 🔴 Critical | Privilege escalation indicator |
| `/etc/shadow` | 🔴 Critical | Credential tampering |
| `/etc/passwd` | 🟠 High | Unauthorized user creation |
| `/etc/ssh/sshd_config` | 🟠 High | SSH misconfiguration |
| `/etc/crontab` | 🟠 High | Persistence via scheduled task |
| `/etc/cron.d/` | 🟠 High | Persistence via scheduled task |
| `/var/log/auth.log` | 🟠 High | Log deletion — Defense Evasion |

---

## Playbook — Step by Step

### STEP 1 — Identify (2 minutes)

When a FIM alert fires, immediately identify:

```
→ Which file was modified?
→ What type of change? (modified / created / deleted / permissions)
→ When exactly? (timestamp)
→ On which server? (agent name)
→ Old hash vs new hash?
```

Check in Wazuh Dashboard:
```
Security Events → FIM → filter by agent: graylog
```

---

### STEP 2 — Validate (5 minutes)

**Was this change planned?**

```
Was there a maintenance window scheduled?
    YES → Was this specific file supposed to change?
          YES → Authorized change → document and close
          NO  → Investigate further

    NO  → Unauthorized change → continue to STEP 3
```

> ⚠️ Note: Change windows are not yet formally defined at OFIR.
> Until defined, treat ALL FIM alerts as potentially unauthorized.

**Check who made the change:**

```bash
# On the Graylog server
last -n 20
who
journalctl -u sshd --since "10 minutes ago"
```

---

### STEP 3 — Investigate (10 minutes)

```bash
# Check what exactly changed in the file
diff /path/to/file /path/to/file.backup

# Check recent commands executed
history

# Check if any suspicious process touched the file
ausearch -f /path/to/file 2>/dev/null

# Check active connections
ss -tulpn
who
```

**Correlate with other alerts:**

```
→ Was there a brute force alert from the same IP recently?
→ Was there an SSH login from an unknown IP before this change?
→ Are there other FIM alerts at the same time?
```

---

### STEP 4 — Contain

**If critical paths modified (ossec.conf, decoders, rules, AR scripts):**

```bash
# Immediately restore from backup
cp /var/ossec/etc/ossec.conf.backup /var/ossec/etc/ossec.conf
systemctl restart wazuh-agent

# Verify pipeline is working
tail -f /var/ossec/logs/ossec.log
```

**If system files modified (passwd, shadow, sudoers):**

```bash
# Check for unauthorized users
cat /etc/passwd | grep -v "nologin\|false" 
cat /etc/sudoers

# Lock suspicious account if found
usermod -L suspicious_user
```

**If log files deleted (auth.log):**

```bash
# Recreate the file
touch /var/log/auth.log
chmod 640 /var/log/auth.log
chown root:adm /var/log/auth.log
systemctl restart rsyslog
```

---

### STEP 5 — Notify

Send notification via Mattermost and email with:

```
🚨 FIM ALERT — [SEVERITY]

File    : [file path]
Change  : [modified / created / deleted]
Time    : [timestamp]
Server  : [agent name]
Old hash: [md5]
New hash: [md5]

Action taken: [what was done]
Next step   : [investigation ongoing / resolved]
```

Escalation:
```
High severity    → Mattermost + Email to Domagoj
Critical severity → Mattermost + Email + Phone call immediately
```

---

### STEP 6 — Close & Document

```
→ Was it authorized? → Document as false positive, tune if needed
→ Was it unauthorized? → Document as incident:
    - What was changed
    - Who changed it (if identified)
    - How they got access
    - What was restored
    - What needs to be fixed to prevent recurrence
```

Update the incident register (COM-05).

---

## Tuning — Reducing False Positives

Some files change legitimately and frequently:

| File | Legitimate change | Solution |
|------|-----------------|----------|
| `/etc/passwd` | Package installs add system users | Whitelist known package install windows |
| `/etc/shadow` | Scheduled password rotation | Document rotation schedule |
| `/var/log/auth.log` | Log rotation by logrotate | Add logrotate to change window |

> ⚠️ Until change windows are formally defined ,
> document all changes manually rather than whitelisting.

---

*Document maintained as part of Phase 3 — Optimisation & Hardening*  
*Last updated: June 2026*
