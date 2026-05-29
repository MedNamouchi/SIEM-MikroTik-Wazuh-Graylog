# MikroTik Resource Monitor Script — Phase 2 (Production)

RouterOS script that monitors CPU and RAM usage every minute and logs
a warning when either exceeds **80%**. These warnings are forwarded to
Graylog via the `[WARN]` logging topic and trigger Wazuh rules `100500`
and `100501`.

---

## Script — resource-monitor

```routeros
/system script set resource-monitor source={
  :local cpu [/system resource get cpu-load];
  :local freeMem [/system resource get free-memory];
  :local totalMem [/system resource get total-memory];
  :local memUsed (($totalMem - $freeMem) * 100 / $totalMem);

  :if ($cpu > 80) do={
    :log warning ("CPU HIGH: cpu-load=" . $cpu . "% on router " . [/system identity get name]);
  }
  :if ($memUsed > 80) do={
    :log warning ("MEMORY HIGH: mem-usage=" . $memUsed . "% on router " . [/system identity get name]);
  }
}
```

---

## Scheduler — run every 1 minute

```routeros
/system scheduler add \
  name="resource-check" \
  interval=00:01:00 \
  on-event="resource-monitor"
```

---

## How it works

```
RouterOS script (every 1 min)
        ↓
  CPU > 80% or RAM > 80%
        ↓
  /log warning "CPU HIGH: cpu-load=X% on router ROUTERNAME"
        ↓
  Graylog receives log via [WARN] topic
        ↓
  Wazuh decoder: mikrotik-resource-high
        ↓
  Wazuh rule 100500 (CPU) or 100501 (RAM) — level 8
```

---

## Log format example

```
OFIR_MAIN_NEW[WARN]: CPU HIGH: cpu-load=87% on router OFIR_MAIN_NEW
OFIR_MAIN_NEW[WARN]: MEMORY HIGH: mem-usage=83% on router OFIR_MAIN_NEW
```

---

## Verify the scheduler is running

```routeros
/system scheduler print
# Expected: resource-check running, interval=1m
```

---

## Adjust thresholds

To change the alert threshold (default 80%), edit the script:

```routeros
# Change 80 to your desired threshold
:if ($cpu > 80) do={ ... }
:if ($memUsed > 80) do={ ... }
```
