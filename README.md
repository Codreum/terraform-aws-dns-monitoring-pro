<p align="center">
  <a href="https://www.codreum.com">
    <img src="docs/brand/logo.png" alt="Codreum" width="200" />
  </a>
</p>

<p align="center">
  <a href="https://www.codreum.com">Website</a> •
  <a href="#quickstart">Quickstart</a> •
  <a href="#support">Support</a>
</p>

# Codreum DNS Monitoring (Pro) — DNSCI-Z (Hosted Zone)

Production-grade DNS observability for **Route 53 hosted zone query logs**: **NXDOMAIN + SERVFAIL + REFUSED + success rate + client error rate + EDNS + TCP share**, with **multi-zone** dashboards, Contributor Insights packs, and opinionated investigation views — deployed into **your AWS account** with **Terraform + CloudWatch**.

✅ Multi-zone support (one deployment can cover many hosted zones)  
✅ Rich dashboards: Ops landing + Investigation + Deep forensics + per-zone dashboards + Top-N drilldowns  
✅ More DNS health signals (beyond NXDOMAIN) + optional anomaly detection  
✅ Built-in alert delivery presets (Email / SMS / Slack via SNS + Chatbot)  
✅ Optional log-group management add-ons (Data Protection, Log Indexing, Log Anomaly Detector, Subscription filters)

> This README is for the **Pro / paid** edition. If you only need NXDOMAIN signals, use the free NXDOMAIN module instead (same concept, fewer metrics and dashboards).

---

## Why use Codreum DNS Monitor?

DNS issues rarely look like “DNS is down.” They show up as:
- rising app latency (timeouts while resolvers retry)
- sporadic 5xx (only some clients / regions / edges impacted)
- failed deployments (wrong names, missing records)
- subtle misroutes (wrong answers, stale caching)

Codreum DNS Monitor is designed for **fast triage**:
- alert on the **right DNS signals** (not just “is port 53 open?”)
- instantly surface **what changed** (Top-N by qname/qtype/edge/client)
- keep everything **inside your AWS account** (no DNS log shipping)

---

## Why AWS CloudWatch (in-account)?

External DNS checkers are useful, but they’re limited:
- they test from a few locations and only for **public DNS**
- they can’t see your real production resolver traffic patterns
- they miss “partial outages” (only some edges / clients / qtypes)

This solution uses your **real Route 53 hosted zone query logs** already in CloudWatch Logs:
- sees failures from **actual clients**
- attributes impact to **top domains / qtypes / edges / source IPs**
- runs fully **in-account** using CloudWatch Logs, Metrics, Alarms, Dashboards and Contributor Insights

> Privacy note: DNS logs stay in your account. Codreum does not receive your DNS logs.

---

## Why DNS monitoring is important

DNS is a shared dependency across:
- service discovery (internal + external)
- authentication and identity flows
- email delivery, webhooks, API gateways
- failover and multi-region routing

When DNS degrades, downstream symptoms are confusing and slow to diagnose. DNS monitoring gives you:
- early warning (error rate shifts before app errors spike)
- attribution (which names / qtypes / edges / clients are failing)
- confidence in changes (spot regressions after deploys, migrations, or record changes)

---

## Why Pro vs NXDOMAIN-only?

The free NXDOMAIN module is intentionally narrow: **NXDOMAIN** signals only.

Pro adds:
- **More DNS metrics** (SERVFAIL, REFUSED, overall client error %, success %, TCP %, EDNS health, low-volume detection)
- **More Contributor Insights packs** (profiles + matrices for qtype / client / edge / proto / rcode / EDNS)
- **More dashboards** (Investigation + Deep Forensics + richer per-zone dashboards and Top-N views)
- **Per-zone control** (choose which metrics/alarms/CI/dashboards each zone gets)
- **Built-in notification wiring** (optional Email/SMS/Slack subscriptions created for you)
- **Licensing & enforcement** (fail-fast license validation + optional periodic checks)

---

## What you get (Pro)

### 1) Metrics (CloudWatch namespace: `Codreum/DNSCI`)
Per hosted zone (ZoneId dimension), Pro can publish and visualize:

**Core volume & errors**
- `ZoneTotal` — total query volume
- `ZoneNXDOMAIN` — NXDOMAIN count + rate (%)
- `ZoneServerError` — SERVFAIL count + rate (%)
- `ZoneRefused` — REFUSED count + rate (%)
- `ZoneClientError` — any `rcode != NOERROR` count + rate (%)
- **Overall error %** — client error rate (%) derived from `ZoneClientError / ZoneTotal`
- **Rare errors** — `(client errors) - (NXDOMAIN + SERVFAIL + REFUSED)` (helps surface FORMERR/NOTIMP/… without extra filters)

**Success**
- `ZoneSuccess` — `rcode == NOERROR` count + success rate (%)

**Protocol & EDNS health**
- `ZoneProtoTCP` — TCP share (%) (UDP/TCP mix shift is often a DNS incident signal)
- `ZoneEdnsNone` — share of queries with EDNS=none (%)
- `ZoneEdnsBad` — share of queries with EDNS=bad (%)

> You choose what’s enabled per zone via `act_metric`.

### 2) Alarms (static thresholds + optional anomaly detection)
For each enabled signal, the module can create:
- **count alarms** (e.g., NXDOMAIN count spikes)
- **rate alarms** (e.g., NXDOMAIN %, SERVFAIL %, overall error %)
- **optional anomaly alarms** (enabled via specific `*_anom` activation flags)
- **low-volume alarm** (`total_low`) to catch silent outages or log pipeline issues

Alarms publish to an SNS topic (default) or to per-zone SNS topics you provide.

### 3) Contributor Insights packs (Top-N + profile views)
Pro adds many optional CI rules to accelerate investigation:
- QTYPE, RCODE, PROTO, EDNS “profiles”
- Error-only profiles (what changes when failures rise)
- Client/edge matrices (who is failing from where)
- High-value qtype focus (A/AAAA/CNAME/MX/TXT)
- Suspicious name Top-N (hunt DGA/random subdomain spikes)

> Enable these per zone via `act_metric` flags like `qtype_profile`, `rcode_profile`, `client_edge_matrix`, etc.

### 4) Dashboards (opinionated investigation flow)
Depending on `act_dashboard`, Pro can create:

**Global dashboards**
- **DNS Ops Landing**: your “start here” page with links, key tiles, and SLO overlays
- **DNS Ops Investigate**: faster drilldowns for incident response
- **DNS Ops Deep Forensics**: heavier views for post-incident / slow-burn debugging  
- **SLO tiles** (optional): overlays based on `dns_slo_config` thresholds (success %, max error %, max TCP %, max EDNS none/bad %)

**Per-zone dashboards**
- **Zone dashboard**: metrics, rates, breakdowns for a single zone
- **Zone Top-N dashboard**: rapid triage tables (domains/qtypes/edges/clients/etc.)

Dashboard names are prefixed, for example:
- `${prefix}-dnsciz-dns-ops-landing`
- `${prefix}-dnsciz-dns-ops-investigate`
- `${prefix}-dnsciz-dns-ops-deep-forensics`
- `${prefix}-dnsciz-zone-<zone-name>`
- `${prefix}-dnsciz-zone-<zone-name>-topn`

### 5) Optional log group management add-ons
Disabled by default; enable per log group when you want them:
- **CloudWatch Logs Data Protection** (audit + optional de-identification for sensitive fields)
- **Log field indexing** for faster Logs Insights / CI workflows
- **CloudWatch Logs Anomaly Detector**
- **Subscription filter management** (advanced; lets you forward only the relevant zone traffic to a destination)

---

## Quickstart

### 0) Before you start: enable hosted zone query logging
For each Route 53 hosted zone you want to monitor:
1. Enable **Query logging**
2. Send logs to a CloudWatch Logs log group in **`us-east-1`** (AWS requirement for public hosted zone query logging)

> If you already have query logs flowing, you can proceed.

### 1) Add the module to Terraform

Paste into `main.tf` (edit values to match your environment):

```hcl
module "codreum_dnsci_pro_zone" {
  # Replace with your actual module source / ref
  source = "github.com/Codreum/terraform-aws-dns-monitoring-pro//modules/zone?ref=vX.Y.Z"

  prefix     = "acme-prod"
  aws_region = "us-east-1" # required for hosted-zone query logs

  # --- Pro license (required) ---
  license = {
    type       = "dnsciz"
    license_id = "LIC-XXXX-XXXX"

    # One deployment can cover many hosted zones
    zone_ids = ["Z123EXAMPLE", "Z456EXAMPLE"]
  }

  # Map each ZoneId to the CloudWatch Logs group that contains its query logs.
  # Value can be a log group name OR a log group ARN.
  subject_log_group_map = {
    "Z123EXAMPLE" = "arn:aws:logs:us-east-1:123456789012:log-group:/aws/route53/zone-Z123:*"
    "Z456EXAMPLE" = "/aws/route53/zone-Z456"
  }

  # --- Per-zone feature toggles ---
  # Must include "total" whenever you enable other metrics (enforced by the module).
  act_metric = {
    "Z123EXAMPLE" = [
      "total",
      "nxdomain",
      "server_error",
      "refused",
      "success",
      "client_error",
      "overall_error",
      "rare_error",
      "proto_tcp",
      "edns_failure",

      # Optional: anomaly alarms (enable explicitly)
      "nxdomain_anom",
      "nxdomain_rate_anom",
      "overall_error_rate_anom",

      # Optional: CI packs (enable explicitly)
      "qtype_profile",
      "rcode_profile",
      "client_volume",
      "edge_imbalance",
      "proto_profile",
      "edns_behavior",
      "client_edge_matrix",
      "qtype_edge_matrix"
    ]

    # A second zone could run a lighter footprint
    "Z456EXAMPLE" = ["total", "nxdomain", "nxdomain_rate_anom"]
  }

  # Dashboards to create (choose any of these tokens, plus any ZoneId in your license)
  act_dashboard = ["opslanding", "slo", "investigation", "forensic", "Z123EXAMPLE", "Z456EXAMPLE"]

  # Optional: alert delivery presets (SNS topic + subscriptions)
  dns_alert_emails = ["dns-oncall@example.com"]

  # Optional: Slack via AWS Chatbot
  enable_slack_notifications = false
  slack_workspace_id         = "T0123456789"
  slack_channel_id           = "C0123456789"
}
```

### 2) Deploy

```bash
terraform init
terraform apply
```

---

## How it works

1. **License check (fail fast)**  
   On `terraform apply`, the module calls Codreum’s license endpoint and validates:
   - account id
   - product type
   - allowed ZoneIds  
   If validation fails, apply fails.

2. **Metrics from logs**  
   CloudWatch Logs **metric filters** match fields from Route 53 hosted zone query logs (CLF) and publish metrics into `Codreum/DNSCI` with `ZoneId` as a dimension.

3. **Alarms**  
   Alarms are created per zone for the enabled signals:
   - count alarms, rate alarms, and optional anomaly alarms
   - notifications routed via SNS (global default or per-zone override)

4. **Contributor Insights rules**  
   CI rules read the same log groups and compute Top-N / profiles used by the dashboards.

5. **Dashboards**  
   Dashboards are created only when requested via `act_dashboard`, and are designed to guide incident response:
   - start at Ops landing
   - drill into per-zone dashboards and Top-N
   - use Investigation / Forensics when needed

6. **(Optional) Log group management**  
   If enabled, the module applies CloudWatch Logs features (data protection, indexing, anomaly detectors, subscription filters) to the underlying log groups.

---

## Prerequisites

- Terraform >= 1.14
- AWS provider >= 6.2
- Hosted zone query logs already flowing into CloudWatch Logs
- **Region constraint:** for hosted zone query logging, the destination log group must be in **`us-east-1`** and this module should be deployed in **`us-east-1`**
- Outbound HTTPS access from your Terraform runner (and from the license watcher Lambda if enabled) to reach Codreum’s license endpoint

---

## Configuration

### Required inputs
- `prefix`
- `aws_region`
- `license` (Pro license object)
- `subject_log_group_map` (ZoneId → log group name/arn)
- `act_metric` (ZoneId → enabled flags) — include `"total"` whenever you enable anything else

### Common optional inputs
- **Dashboards:** `act_dashboard` (global tokens + ZoneIds)
- **Threshold tuning:** `metric_override` (per-zone thresholds/periods/action toggles)
- **SLO overlays:** `dns_slo_config` (success %, max error %, max TCP %, max EDNS none/bad)
- **Alert routing:** `subject_sns_topic_map` (ZoneId → SNS topic ARN)
- **Notification presets:** `dns_alert_emails`, `dns_alert_sms`, `dns_alert_https_endpoints`, `sns_kms_key_id`
- **Slack notifications:** `enable_slack_notifications`, `slack_workspace_id`, `slack_channel_id`
- **Log group management (off by default):**
  - `log_data_protection_override`
  - `log_index_override`
  - `log_anomaly_override`
  - `log_anomaly_detector_enabled`
  - `log_subscription_overrides`

### Example: per-zone alert routing
Send one zone to a dedicated SNS topic:

```hcl
subject_sns_topic_map = {
  "Z123EXAMPLE" = "arn:aws:sns:us-east-1:123456789012:dns-prod-critical"
}
```

### Example: tweak thresholds
```hcl
metric_override = {
  "Z123EXAMPLE" = {
    nxdomain_count = {
      threshold          = 500
      evaluation_periods = 2
      period             = 300
    }
    overall_error_rate = {
      threshold_pct      = 2.0
      evaluation_periods = 3
      period             = 300
    }
  }
}
```

---

## What you’ll see after deploy

After `terraform apply`, you’ll have CloudWatch **dashboards**, **alarms**, and **Contributor Insights** rules created in your AWS account.

Tip: in **CloudWatch → Dashboards**, search for your `prefix` (e.g., `acme-prod-*`).

### Dashboards
- Global dashboards (when enabled via `act_dashboard`):
  - `${prefix}-dnsciz-dns-ops-landing`
  - `${prefix}-dnsciz-dns-ops-investigate`
  - `${prefix}-dnsciz-dns-ops-deep-forensics`
- Per-zone dashboards (when you include the ZoneId in `act_dashboard`):
  - `${prefix}-dnsciz-zone-<zone-name>`
  - `${prefix}-dnsciz-zone-<zone-name>-topn`

### Metrics & alarms
- Metrics appear under **CloudWatch → Metrics → `Codreum/DNSCI`**
- Alarms appear under **CloudWatch → Alarms**, named with your prefix and zone name
- (Optional) a license status metric/alarm is created under `Codreum/License` to indicate license validity

### Contributor Insights
- CI rules appear under **CloudWatch → Contributor Insights**
- Count and cost scale with the number of enabled CI packs and the number of zones

---

## Costs (AWS billed)

This module creates CloudWatch resources that may incur AWS charges depending on region and usage.

Typical cost drivers:
- **Custom metrics** published by log metric filters (`Codreum/DNSCI`)
- **CloudWatch alarms** (static + anomaly)
- **Contributor Insights rules** (Top-N / profiles / matrices)
- **CloudWatch Logs features** if enabled (Data Protection, Log Indexing, Log Anomaly Detector)
- **Logs Insights queries** you run from dashboards (charged per GB scanned)

Recommendation: start with a small `act_metric` set for one zone, validate signal value, then scale out.

---

## Security & data

- DNS logs remain in **your AWS account** (CloudWatch Logs).
- The module’s licensing check makes an HTTPS request to Codreum to validate your subscription (no DNS logs are sent).
- Optional CloudWatch Logs Data Protection can audit / de-identify sensitive fields inside CloudWatch Logs (when enabled).
- Notifications are delivered only through **SNS** destinations you configure (email/SMS/Slack/HTTPS endpoints).

---

## Limitations

- This module (DNSCI-Z) is for **hosted zone query logs**. Hosted zone query logging requires **`us-east-1`** for the destination log group.
- Requires Route 53 hosted zone query logs in **CLF** format (fields like `hosted_zone_id`, `qname`, `qtype`, `rcode`, `proto`, `edge`, `rip`, `edns`).
- Dashboards expect the underlying metrics to be enabled; disabling signals may produce empty tiles.
- Log group management features are **opt-in** and may not be available in all partitions/regions.

---

## Support

- Pro customers: reach out via your Codreum support channel (email / ticket portal as provided with your subscription).
- If this repo is mirrored internally, file an issue with:
  - your `prefix`
  - affected ZoneId(s)
  - which `act_metric` flags are enabled
  - the CloudWatch alarm name(s) / dashboard name(s)
