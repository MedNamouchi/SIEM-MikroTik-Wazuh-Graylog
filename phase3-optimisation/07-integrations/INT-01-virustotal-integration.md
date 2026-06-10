# INT-01 — VirusTotal Integration

> **Task:** Activate VirusTotal integration  
> **Author:** Mohamed Amine Namouchi  
> **Date:** June 2026  
> **Status:** ✅ Complete

---

## Context

When FIM detects a new or modified file on the Graylog server,
Wazuh automatically sends the file hash to VirusTotal to check
if it is a known malware.

```
FIM detects new file
        ↓
Wazuh extracts MD5/SHA1/SHA256 hash
        ↓
Wazuh sends hash to VirusTotal API
        ↓
VirusTotal checks against 60+ antivirus engines
        ↓
Result: clean or malicious → alert generated
```

---

## Configuration

Added to `/var/ossec/etc/ossec.conf` on Wazuh Manager:

```xml
<!-- VirusTotal Integration -->
<integration>
  <name>virustotal</name>
  <api_key>VIRUSTOTAL_API_KEY</api_key>
  <rule_id>554,550,553</rule_id>
  <alert_format>json</alert_format>
</integration>
```

Rules monitored:
```
554 → new file detected by FIM
550 → file modified
553 → file deleted
```

---

## How It Works

```
Rule 554/550/553 fires (FIM event)
        ↓
wazuh-integratord sends hash to VirusTotal API
        ↓
VirusTotal responds with scan results
        ↓
Wazuh generates alert:
  Rule 87104 → "VirusTotal: Alert - No positives found" (clean)
  Rule 87105 → "VirusTotal: Alert - X engines detected malware" (malicious)
```

---

## Validation

Test performed on 2026-06-10:

```bash
# Created test file in FIM-monitored path
echo "test virustotal" > /etc/cron.d/test-vt
```

Result in alerts.log:
```json
{
  "virustotal": {
    "found": 1,
    "malicious": 0,
    "positives": 0,
    "total": 60,
    "source": {
      "file": "/etc/cron.d/test-vt",
      "md5": "1af46b82cb5ecf13cc533ef57ab07278"
    }
  }
}
Rule: 87104 → "VirusTotal: Alert - No positives found" ✅
```

---

## Alert Examples

### Clean file
```
Rule 87104 — level 3
VirusTotal: Alert - /path/to/file - No positives found
positives: 0/60
```

### Malicious file
```
Rule 87105 — level 12
VirusTotal: Alert - /path/to/file - X engines detected malware
positives: X/60
→ Immediate investigation required !
```

---

## Limitations (Free API)

```
→ 4 requests per minute
→ 500 requests per day
→ Sufficient for small infrastructure
```

---




*Document maintained as part of Phase 3 — Optimisation & Hardening*  
*Last updated: June 2026*
