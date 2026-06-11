# COM-03 — Compliance Dashboards in Wazuh

> **Task:** Activate compliance dashboards in Wazuh  
> **Author:** Mohamed Amine Namouchi  
> **Date:** June 2026  
> **Status:** ✅ Complete

---

## Context

Wazuh includes built-in compliance dashboards that automatically
map alerts to regulatory frameworks based on the group tags
added in our custom rules (DET-02).

---

## Available Dashboards

```
Wazuh Dashboard → Modules:
→ GDPR
→ PCI DSS
→ NIST 800-53  ✅ Validated
→ HIPAA
→ TSC
```

---

## NIST 800-53 Dashboard — Validated

Confirmed active on 2026-06-11:

```
Total alerts        : 8,386
Max level detected  : 15

Top requirements triggered:
→ AU.14 — Audit Record Generation
→ AC.7  — Unsuccessful Login Attempts
→ AU.12 — Audit Record Creation
→ SI.7  — Software & Information Integrity
→ AU.6  — Audit Record Review
→ CM.6  — Configuration Settings
```

Agents covered:
```
→ punica.ofir.hr (agent 002)
→ graylog (agent 001)
→ wazuh (agent 000)
```

---

## How It Works

Compliance tags in our custom rules automatically feed the dashboards:

```xml
<!-- Example from rule 100302 -->
<group>authentication_failures,
  gdpr_IV_35.7.d,
  gdpr_IV_32.2,
  nist_800_53_AC.7,
  pci_dss_10.2.4,
</group>
```

No additional configuration needed — tags drive the dashboards. ✅

---



*Document maintained as part of Phase 3 — Optimisation & Hardening*  
*Last updated: June 2026*
