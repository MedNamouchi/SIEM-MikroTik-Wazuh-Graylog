# DET-04 — Password Spraying & Distributed Attack Detection

> **Task:** Create password spraying detection rule  
> **Author:** Mohamed Amine Namouchi  
> **Date:** June 2026  
> **Status:** ✅ Complete

---

## Context

Classic brute force (rule 100302) detects one IP attacking one user.
Sophisticated attackers use distributed techniques to evade detection:

```
Classic brute force (covered by 100302):
→ Same IP + Same user + Many attempts
→ admin:aaa from 1.1.1.1
→ admin:bbb from 1.1.1.1
→ admin:ccc from 1.1.1.1

Password spraying (covered by 100700):
→ Same user + Different IPs
→ admin:Password1 from 1.1.1.1
→ admin:Password1 from 2.2.2.2
→ admin:Password1 from 3.3.3.3

Distributed attack (covered by 100701):
→ Different IPs + Different users
→ admin:111   from 195.23.2.3
→ admin:1111  from 195.23.2.4
→ admin1:1234 from 77.22.33.22
→ admin1:4234 from 77.23.2.3
→ admin2:334  from 33.23.2.3
```

---

## Rules Added

### Rule 100700 — Password Spraying

```xml
<rule id="100700" level="12" frequency="5" timeframe="60">
  <if_matched_sid>100301</if_matched_sid>
  <same_field>dstuser</same_field>
  <description>MikroTik: Password spraying — same user $(dstuser)
  attacked from multiple IPs</description>
  <group>authentication_failures,gdpr_IV_35.7.d,nist_800_53_AC.7,
  pci_dss_10.2.4,pci_dss_11.4,</group>
  <mitre>
    <id>T1110.003</id>
  </mitre>
</rule>
```

**Logic:** Same username fails 5+ times from different IPs in 60 seconds.

### Rule 100701 — Distributed Attack

```xml
<rule id="100701" level="14" frequency="10" timeframe="60">
  <if_matched_sid>100301</if_matched_sid>
  <description>MikroTik: Distributed attack — 10+ auth failures
  from multiple IPs and users</description>
  <group>authentication_failures,distributed_attack,gdpr_IV_35.7.d,
  nist_800_53_AC.7,pci_dss_10.2.4,pci_dss_11.4,</group>
  <mitre>
    <id>T1110.003</id>
  </mitre>
</rule>
```

**Logic:** 10+ auth failures regardless of IP or user in 60 seconds.

---

## Detection Coverage

| Attack Type | Rule | Frequency | Timeframe | MITRE |
|-------------|------|-----------|-----------|-------|
| Brute force (same IP/user) | 100302 | 5 failures | 60s | T1110.001 |
| Password spraying (same user) | 100700 | 5 failures | 60s | T1110.003 |
| Distributed attack (diff IP+user) | 100701 | 10 failures | 60s | T1110.003 |

---

## False Positive Considerations

```
Rule 100700 — Low FP risk
→ Unlikely that multiple IPs legitimately fail
   the same username at the same time

Rule 100701 — Medium FP risk
→ If many users fail auth simultaneously
   (e.g. password policy change)
→ Mitigate with CDB List (DET-03) for known admin IPs
→ Tune frequency threshold based on observed traffic
```

---


*Document maintained as part of Phase 3 — Optimisation & Hardening*  
*Last updated: June 2026*
