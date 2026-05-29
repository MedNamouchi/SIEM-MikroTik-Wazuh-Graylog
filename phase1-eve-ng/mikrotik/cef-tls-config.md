# MikroTik CEF over TLS Configuration

Configuration of remote logging in CEF format over TLS for all 6 MikroTik CHR routers.

---

## Prerequisites

- RouterOS **7.23+** (required for CEF over TLS support)
- Graylog TLS certificate (`graylog.crt`) transferred to the router
- Graylog CEF TCP input running on port **6514**

---

## Step 1 — Transfer the Certificate

Run this from the Graylog server for each router:

```bash
scp /etc/graylog/server/certs/graylog.crt admin@ROUTER_IP:graylog.crt
```

---

## Step 2 — Import the Certificate on MikroTik

```routeros
/certificate import file-name=graylog.crt passphrase=""
```

Verify the certificate has the correct key usage:

```routeros
/certificate print detail
```

Expected output must show:
```
key-usage: digital-signature, key-encipherment, tls-server
trusted: yes
```

> ⚠️ If `tls-server` is missing, the TLS protocol option will NOT appear in the logging
> action. Regenerate the certificate with `extendedKeyUsage=serverAuth`.

---

## Step 3 — Create the Logging Action

> ⚠️ **Critical:** `remote-protocol=tls` MUST be set in the `add` command.
> RouterOS returns a syntax error if you try to set it afterwards with `set`.
> If you made a mistake, delete the action and recreate it.

```routeros
/system logging action add \
  name=graylogcef \
  target=remote \
  remote=GRAYLOG_SERVER_IP \
  remote-port=6514 \
  remote-log-format=cef \
  remote-protocol=tls
```

Verify:

```routeros
/system logging action print detail
# Expected: remote-protocol=tls
```

---

## Step 4 — Configure Logging Topics

Each router uses a unique prefix in the format `MKT[ID][TYPE]`.  
The ID uniquely identifies the router; the TYPE categorizes the log topic.

### Router 1 — MKT[001]
```routeros
/system logging add topics=firewall prefix="MKT[001][FW]"   action=graylogcef
/system logging add topics=system   prefix="MKT[001][SYS]"  action=graylogcef
/system logging add topics=info     prefix="MKT[001][INFO]" action=graylogcef
```

### Router 2 — MKT[002]
```routeros
/system logging add topics=firewall prefix="MKT[002][FW]"   action=graylogcef
/system logging add topics=system   prefix="MKT[002][SYS]"  action=graylogcef
/system logging add topics=info     prefix="MKT[002][INFO]" action=graylogcef
```

### Router 3 — MKT[003]
```routeros
/system logging add topics=firewall prefix="MKT[003][FW]"   action=graylogcef
/system logging add topics=system   prefix="MKT[003][SYS]"  action=graylogcef
/system logging add topics=info     prefix="MKT[003][INFO]" action=graylogcef
```

### Router 4 — MKT[004]
```routeros
/system logging add topics=firewall prefix="MKT[004][FW]"   action=graylogcef
/system logging add topics=system   prefix="MKT[004][SYS]"  action=graylogcef
/system logging add topics=info     prefix="MKT[004][INFO]" action=graylogcef
```

### Router 5 — MKT[005]
```routeros
/system logging add topics=firewall prefix="MKT[005][FW]"   action=graylogcef
/system logging add topics=system   prefix="MKT[005][SYS]"  action=graylogcef
/system logging add topics=info     prefix="MKT[005][INFO]" action=graylogcef
```

### Router 6 — MKT[006]
```routeros
/system logging add topics=firewall prefix="MKT[006][FW]"   action=graylogcef
/system logging add topics=system   prefix="MKT[006][SYS]"  action=graylogcef
/system logging add topics=info     prefix="MKT[006][INFO]" action=graylogcef
```

---

## Verification

Check that logs are arriving in Graylog:

```bash
sudo ss -tulnp | grep 6514
# Expected: tcp LISTEN 0 4096 *:6514 *:* users:(("java",...))
```

Then go to **Graylog → Search** and filter by `device_vendor:MikroTik`.  
Logs should appear within seconds of any router activity.
