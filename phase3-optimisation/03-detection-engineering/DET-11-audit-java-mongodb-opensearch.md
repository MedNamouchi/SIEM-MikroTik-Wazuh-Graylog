# DET-11 — Audit Java, MongoDB and OpenSearch Versions

> **Task:** Audit Java and MongoDB/OpenSearch versions on Graylog server  
> **Author:** Mohamed Amine Namouchi  
> **Date:** June 2026  
> **Status:** ✅ Complete

---

## Context

Java, MongoDB and OpenSearch are the core components of the Graylog
log pipeline and are frequently targeted by CVEs.

```
If Java is compromised     → Graylog is compromised
If MongoDB is compromised  → Graylog config is stolen/modified
If OpenSearch is compromised → Wazuh alerts can be deleted/falsified
```

---

## Two Audit Methods

### Method 1 — Manual Audit

Check the installed version directly on the server, then search
for known CVEs manually on official sources.

**Step 1 — Get the version:**
```bash
# Java
/usr/share/graylog-server/jvm/bin/java -version

# MongoDB
mongod --version

# OpenSearch
ls /usr/share/graylog-datanode/dist/ | grep opensearch
```

**Step 2 — Search for CVEs:**
```
→ https://nvd.nist.gov/vuln/search
→ https://www.mongodb.com/resources/products/alerts
→ https://opensearch.org/security/
→ https://openjdk.org/groups/vulnerability/advisories/
```

**Example:** Searching "OpenSearch 2.19.3 CVE" reveals
CVE-2025-9624 (DoS via complex query — fixed in 2.19.4).

---

### Method 2 — Automated Audit with Wazuh

Wazuh Vulnerability Detection does this automatically.

**Prerequisites — enable in ossec.conf (Manager):**

```xml
<!-- System inventory — must be enabled on each agent -->
<wodle name="syscollector">
  <disabled>no</disabled>
  <interval>1h</interval>
  <scan_on_start>yes</scan_on_start>
  <packages>yes</packages>
</wodle>

<!-- Vulnerability Detection — must be enabled on Manager -->
<vulnerability-detection>
  <enabled>yes</enabled>
  <index-status>yes</index-status>
  <feed-update-interval>60m</feed-update-interval>
</vulnerability-detection>
```

**How it works:**
```
Syscollector (every 1h)
→ Inventories all packages installed on the agent

Vulnerability Detection (every 60min)
→ Compares package versions against NVD CVE database
→ Generates alerts for vulnerable packages

Results visible in:
Wazuh Dashboard → Vulnerability Detection → Explore agent → graylog
```

This method covers all packages automatically — not just
Java, MongoDB and OpenSearch.

---

## Versions Audited — Example
| Component | Version | Status |
|-----------|---------|--------|
| Java (Temurin) | 21.0.10 | ⚠️ Upgrade recommended |
| MongoDB | 8.0.23 | ✅ Up to date |
| OpenSearch | 2.19.3 | ⚠️ Upgrade to 2.19.4+ |

---



*Document maintained as part of Phase 3 — Optimisation & Hardening*  
*Last updated: June 2026*
