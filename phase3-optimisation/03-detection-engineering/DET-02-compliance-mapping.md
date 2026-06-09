# DET-02 — Compliance Tags Mapping

> **Task:** Add compliance tags to existing rules  
> **Author:** Mohamed Amine Namouchi  
> **Date:** June 2026  
> **Status:** ✅ Complete

---

## What are Compliance Tags

Compliance tags are standard identifiers added to the `<group>` field
of Wazuh rules. They map each alert to a specific regulatory requirement.

Adding compliance tags provides:

```
→ Populated compliance dashboards in Wazuh (GDPR, NIST, PCI DSS)
→ Evidence that security monitoring covers regulatory requirements
→ Faster audit responses — alerts are pre-mapped to controls
→ Standard language for compliance reporting
```

---

## Frameworks Covered

| Framework | Coverage | Purpose |
|-----------|---------|---------|
| GDPR | Article IV_35.7.d + IV_32.2 | Data protection + security of processing |
| NIST 800-53 | AC.7, AU.12, CM.6, SI.4 | Access control + audit + config management |
| PCI DSS | 10.2.4, 10.2.5, 10.2.6, 10.6.1, 11.4 | Log monitoring + audit trails |

---

## Rules Mapping — Complete Table

### Firewall Rules

| Rule ID | Description | GDPR | NIST | PCI DSS |
|---------|-------------|------|------|---------|
| 100200 | Firewall event | IV_35.7.d | AU.12 | 10.6.1 |
| 100201 | Allowed connection | IV_35.7.d | AU.12 | 10.6.1 |
| 100202 | Blocked connection | IV_35.7.d | AU.12 | 10.6.1 |
| 100203 | Event on main router | IV_35.7.d | AU.12 | 10.6.1 |
| 100204 | Access to web server | IV_35.7.d | SI.4 | 10.6.1 |
| 100205 | Port scan detected | IV_35.7.d | SI.4 | 11.4 |
| 100206 | External inbound traffic | IV_35.7.d | SI.4 | 10.6.1 |
| 100207 | Traffic via VPN | IV_35.7.d | AU.12 | 10.6.1 |

### Authentication Rules

| Rule ID | Description | GDPR | NIST | PCI DSS |
|---------|-------------|------|------|---------|
| 100300 | Login success | IV_35.7.d | AC.7 | 10.2.5 |
| 100301 | Login failure | IV_35.7.d | AC.7 | 10.2.4 |
| 100302 | Brute force | IV_35.7.d + IV_32.2 | AC.7 | 10.2.4 + 11.4 |
| 100303 | Logout | IV_35.7.d | AC.7 | 10.2.5 |
| 100304 | Login success after failures | IV_35.7.d + IV_32.2 | AC.7 | 10.2.4 |

### System Rules

| Rule ID | Description | GDPR | NIST | PCI DSS |
|---------|-------------|------|------|---------|
| 100400 | Conscious reboot | IV_35.7.d | CM.6 | 10.2.6 |
| 100401 | Unexpected reboot | IV_35.7.d | CM.6 | 10.2.6 |
| 100402 | Router crash cause | IV_35.7.d | CM.6 | 10.2.6 |
| 100403 | Config change | IV_35.7.d | CM.6 | 10.2.6 |

### Resource Monitoring Rules

| Rule ID | Description | GDPR | NIST | PCI DSS |
|---------|-------------|------|------|---------|
| 100500 | CPU HIGH | IV_35.7.d | AU.12 | 10.6.1 |
| 100501 | MEMORY HIGH | IV_35.7.d | AU.12 | 10.6.1 |

### Agent Monitoring Rules

| Rule ID | Description | GDPR | NIST | PCI DSS |
|---------|-------------|------|------|---------|
| 100600 | Agent stopped | IV_35.7.d | AU.12 | 10.6.1 |
| 100601 | Agent disconnected | IV_35.7.d | AU.12 | 10.6.1 |

---

## Tag Reference

| Tag | Framework | Article / Control | Meaning |
|-----|-----------|------------------|---------|
| `gdpr_IV_35.7.d` | GDPR | Article 35.7.d | Security monitoring as part of data protection |
| `gdpr_IV_32.2` | GDPR | Article 32.2 | Security of processing — risk assessment |
| `nist_800_53_AC.7` | NIST 800-53 | AC-7 | Unsuccessful login attempts |
| `nist_800_53_AU.12` | NIST 800-53 | AU-12 | Audit record generation |
| `nist_800_53_CM.6` | NIST 800-53 | CM-6 | Configuration settings |
| `nist_800_53_SI.4` | NIST 800-53 | SI-4 | System monitoring |
| `pci_dss_10.2.4` | PCI DSS | 10.2.4 | Invalid logical access attempts |
| `pci_dss_10.2.5` | PCI DSS | 10.2.5 | Use of identification and authentication |
| `pci_dss_10.2.6` | PCI DSS | 10.2.6 | Initialization/stopping of audit logs |
| `pci_dss_10.6.1` | PCI DSS | 10.6.1 | Review of security events daily |
| `pci_dss_11.4` | PCI DSS | 11.4 | Detection of intrusions |

---

## Compliance Coverage Map

```
GDPR:
✅ Article 35.7.d → all 21 rules
✅ Article 32.2   → brute force + suspicious auth rules

NIST 800-53:
✅ AC.7  → authentication rules (login/logout/brute force)
✅ AU.12 → firewall + resource + agent monitoring rules
✅ CM.6  → system rules (reboot + config change)
✅ SI.4  → port scan + external traffic + web server

PCI DSS:
✅ 10.2.4 → login failures + brute force
✅ 10.2.5 → login success + logout
✅ 10.2.6 → reboot + config change + agent down
✅ 10.6.1 → firewall + resource + agent monitoring
✅ 11.4   → port scan + brute force
```

---

## Validation

After applying compliance tags, restart the manager and verify
tags appear in alerts:

```bash
systemctl restart wazuh-manager
tail -f /var/ossec/logs/alerts/alerts.log | grep "gdpr\|nist\|pci"
```

Compliance dashboards in Wazuh Dashboard:
```
Security → Compliance → GDPR ✅
Security → Compliance → NIST 800-53 ✅
Security → Compliance → PCI DSS ✅
```

---


*Document maintained as part of Phase 3 — Optimisation & Hardening*  
*Last updated: June 2026*
