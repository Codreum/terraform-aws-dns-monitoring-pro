# DNSCI-Z main.tf templates (copy/paste)

This file contains **twenty** example `main.tf` templates for Codreum DNSCI‑Z (Hosted Zone) Pro.
Each template is self-contained and intended to be copy/pasteable.

**Replace these placeholders in every template (where applicable):**

- `lic_xxxxx...` → your Codreum License ID
- `Z123...` → your hosted zone IDs
- log group ARNs in `subject_log_group_map`
- Slack IDs if you enable Slack notifications
- `+1555...` phone numbers if you enable SMS subscriptions
- `https://hooks...` endpoints if you enable HTTPS subscriptions
- `prefix` and tags

> Notes on dashboards:
> - `act_dashboard` controls **dashboard creation**.
> - Dashboards are mostly **metric-backed**, so widgets only show data if the required metric flags are enabled in `act_metric`.
> - **Zone Top‑N dashboards** are **Logs Insights** widgets, so they do *not* require `act_metric`, but they *do* require query logs to be flowing and parseable.
> - If you set `enable_zone_name_lookup = false`, dashboards and alarms may display **Zone IDs** instead of friendly zone names, and the module won’t require `route53:GetHostedZone`.
> - `dns_alert_https_endpoints` uses SNS HTTPS subscriptions, which require subscription confirmation. Use endpoints that can handle SNS confirmations (or confirm manually where appropriate).

>
> Notes on log-group keyed overrides:
> - Most log-management overrides (`log_data_protection_override`, `log_anomaly_override`, `log_index_override`, `log_subscription_overrides`) are keyed by **log group name** (e.g. `"/aws/route53/zone-1"`), even if your `subject_log_group_map` uses **ARNs**.

---

## Common provider boilerplate (used in all templates)

```hcl
terraform {
  required_version = ">= 1.14.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.2.0"
    }
    http    = { source = "hashicorp/http", version = ">= 3.4.2" }
    archive = { source = "hashicorp/archive", version = ">= 2.4.0" }
  }
}

provider "aws" {
  region = "us-east-1"
}
```

---

## Template 01 — All dashboards enabled (full widget data everywhere)

**What you get**

- Global dashboards: **Ops Landing**, **Investigations**, **Deep Forensics**
- Per-zone dashboards + Zone Top‑N dashboards for every licensed zone token you include
- **Full widget population** (all the metrics those dashboards expect)

**Why use it**

- You want the complete out-of-box incident workflow across **fleet + zone drilldowns**.

**Minimum `act_metric` to fully populate all dashboards** (per zone)

- `total`, `success`, `client_error`, `nxdomain`, `refused`, `server_error`, `proto_tcp`, `edns_failure`

---

## Template 02 — Ops Landing only (full widget data)

**What you get**

- Only **DNS Ops Landing** dashboard (fleet health)
- All Landing widgets populated (SLIs + hotspots + error stacks)

**Minimum `act_metric` for full Landing** (per zone)

- `total`, `success`, `client_error`, `nxdomain`, `refused`, `server_error`, `proto_tcp`, `edns_failure`

---

## Template 03 — Investigations only (full widget data)

**What you get**

- Only **DNS Ops Investigations** dashboard (cross-zone triage)
- Volume hotspots + QTYPE hotspots + error hotspots + EDNS health + Top‑N client error by zone

**Minimum `act_metric` for full Investigations** (per zone)

- `total`, `nxdomain`, `client_error`, `refused`, `server_error`, `edns_failure`

---

## Template 04 — Deep Forensics only (full widget data)

**What you get**

- Only **DNS Ops Deep Forensics** (global breakdowns)
- Error breakdown + QTYPE mix + protocol mix (UDP vs TCP)

**Minimum `act_metric` for full Deep Forensics** (per zone)

- `total`, `client_error`, `nxdomain`, `refused`, `server_error`, `proto_tcp`

---

## Template 05 — Per-zone dashboards only (full widget data)

**What you get**

- **Zone dashboard + Zone Top‑N** for selected zones
- No global dashboards
- Full per-zone control panel signals

**Minimum `act_metric` for a complete zone dashboard** (per zone)

- `total`, `success`, `client_error`, `nxdomain`, `refused`, `server_error`, `proto_tcp`, `edns_failure`

---

## Template 06 — Sensible default (useful dashboards + useful alarms + useful CI)

**What you get**

- Dashboards: **Ops Landing + Investigations**, plus **per-zone dashboards** for key zones
- Metrics for SLI + triage signals
- Static alarms for core signals (+ optional derived alarms)
- High-value Contributor Insights pack for “what changed?” and “who is driving it?”

**Why use it**

- Good default for production: quick “is DNS healthy?” + fast cross-zone triage + per-zone drilldown + actionable CI views.

---

## Template 07 — Log management + Slack + email (with useful dashboards)

**What you get**

- Dashboards: Ops Landing + Investigations + per-zone (example)
- Email + Slack notifications (via SNS + AWS Chatbot)
- Optional CloudWatch Logs management add-ons:
  - Data Protection policy (audit/de-identify per your config)
  - Anomaly detector
  - Index policy

**Why use it**

- You want **production ergonomics** (fast queries, safer logs, and alerting routed to humans).

---

## Template 08 — No dashboards; static alarms only + Slack + email

**What you get**

- No dashboards (`act_dashboard` omitted)
- Static alarms for the main DNS health signals
- Slack + email delivery

**Why use it**

- You want alerting only (e.g., you already have dashboards elsewhere, or you’re rolling out in phases).

**Tip**

- Percent alarms generally require `total` as the denominator, so include `total` for each zone.

---

## Template 09 — Per-zone dashboards + Zone Top‑N + sensible static alarms (Slack + email)

**What you get**

- Per-zone dashboards + Zone Top‑N dashboards for selected zones
- No global dashboards
- Sensible static alarms for the same zones
- Slack + email delivery

**Why use it**

- Teams own zones independently and mostly work from per-zone views and Top‑N during incidents.

---

## Template 10 — Phased rollout (dashboards now, metrics later)

**What you get**

- All dashboards created up front (global + per-zone), so teams can bookmark and share links immediately.
- Only a **canary zone** has full metric coverage at first; other zones show **No data** for metric widgets until you enable their metrics.
- Zone Top‑N tables still work for *all* zones (Logs Insights), as long as query logs are flowing.

**Why use it**

- You’re onboarding DNSCI‑Z safely: start with one zone, validate signal quality and alert noise, then expand.

> Implementation note: Many modules accept `act_metric` only for zones you want enabled.
> To avoid validation issues, this template **omits** zones that are not yet enabled.
> If your module supports explicit empty lists, you may add `"Z123NEXT1" = []` style entries.

---

## Template 11 — Top‑N / Logs Insights only (no custom metrics)

**What you get**

- Per‑zone dashboards are created, but you intentionally **do not** create any `Codreum/DNSCI` metrics.
- Zone **Top‑N** tables still populate (they are Logs Insights widgets).
- Metric-backed widgets will show **No data** (expected).

**Why use it**

- You want an ultra‑light “investigation pack” with minimal CloudWatch custom metric + alarm cost.

---

## Template 12 — Per-zone notification routing + encrypted SNS

**What you get**

- A single default SNS topic (module-managed) for most zones, **encrypted with KMS**.
- Critical zones routed to a separate SNS topic (PagerDuty/incident paging, etc.) using `subject_sns_topic_map`.
- Slack/email subscriptions on the default topic for “standard severity”.

**Why use it**

- Different ownership / paging policies per zone.

---

## Template 13 — Anomaly-centric alerting (seasonal traffic)

**What you get**

- Metrics + anomaly alarms for traffic patterns that change throughout the day/week.
- Optional `metric_override` examples to tune evaluation periods and enable/disable static vs anomaly actions.

**Why use it**

- Your DNS has strong diurnal/weekly seasonality and static thresholds are noisy.

---

## Template 14 — Dashboard UX tuning (lookbacks, tiles, Top‑N size, SLO overlays)

**What you get**

- Dashboards with shorter/longer default lookback windows.
- SLI tiles that update more frequently (smaller “last Xm”).
- Larger Top‑N tables and runbook links.
- SLO lines/annotations overlaid on key widgets.

**Why use it**

- You want dashboards to match your operational rhythm (fast incidents vs slow-burn debugging).

---

## Template 15 — Forward a filtered subset of DNS logs (subscription filters)

**What you get**

- Optional subscription filters that forward a subset of Route 53 query logs to a downstream system (Firehose/Lambda/etc.).
- Useful for threat hunting, SIEM pipelines, or long-retention archives.

**Why use it**

- You want to keep the primary workflow in CloudWatch, but also stream a subset of logs elsewhere.

> Subscription filter patterns depend on your log format (Route 53 hosted zone query logs are CLF-like).
> Treat the pattern below as a placeholder and adjust to your log lines.
> **Recommendation:** validate the pattern first in **CloudWatch Logs Insights** (quick iterate) before rolling it into a subscription filter.

---

## Template 16 — SMS paging only (no Slack/email, alarms-only)

**What you get**

- No dashboards (intentionally)
- Core health alarms delivered via **SNS → SMS**
- Useful for “wake someone up” / minimal on-call routing

**Why use it**

- You want the smallest operational footprint: **alarms + SMS**, nothing else.

> Tip: include `total` per zone if you use any rate/percent alarms, since it’s commonly used as the denominator.

---

## Template 17 — HTTPS/webhook alerting (SNS HTTPS subscriptions)

**What you get**

- Dashboards (example: Ops Landing + Investigations + per-zone)
- Static alarms delivered to **HTTPS endpoint(s)** via SNS subscription
- Optional SNS encryption via KMS key

**Why use it**

- You have an internal webhook receiver / incident intake service, or a vendor endpoint that supports SNS confirmations.

---

## Template 18 — Least-privilege deployment (disable Route 53 zone name lookup)

**What you get**

- Dashboards + metrics/alarms (normal operation)
- **No Route 53 zone-name lookup** calls (no need for `route53:GetHostedZone`)

**Why use it**

- Your Terraform role is restricted (cross-account, minimal IAM) and you want to avoid Route 53 API permissions.

---

## Template 19 — Contributor Insights hunting pack (CI-only) + Top-N dashboards + indexing

**What you get**

- Per-zone dashboards created (Zone + Zone Top-N)
- **Contributor Insights rules only** (no custom metrics/alarms)
- Optional field indexing to speed up investigations

**Why use it**

- You want a low-metric-cost footprint focused on **“who/what changed?”** hunting:
  - top clients, suspicious qnames, qtype mix, rcode mix, edge imbalance, matrices

> Expected behavior: metric-backed widgets will show **No data**, but **Zone Top-N** (Logs Insights) works as long as query logs are flowing/parseable. CI views appear under CloudWatch Contributor Insights.

---

## Template 20 — Log hygiene only (Data Protection + indexing), with anomaly detectors disabled

**What you get**

- Dashboards + metrics (example)
- CloudWatch Logs **Data Protection** + **Field Indexing**
- Explicitly disables CloudWatch Logs anomaly detectors via `log_anomaly_detector_enabled = false`

**Why use it**

- You want safer/faster logs (privacy + query performance), but anomaly detectors are not desired (policy/cost/noise).

---

## Quick pick guide (expanded)

- **Want everything** → Template 01
- **Fleet health only** → Template 02
- **Cross-zone triage only** → Template 03
- **Global breakdowns only** → Template 04
- **Zone-focused ops** → Template 05 (dashboards) or Template 09 (dashboards + alarms + notifications)
- **Best default for production** → Template 06
- **Need log management + Slack/email** → Template 07
- **Alerting only (no dashboards)** → Template 08
- **Phased rollout (dashboards first)** → Template 10
- **Top‑N only, minimal spend** → Template 11
- **Different paging per zone + KMS** → Template 12
- **Seasonal traffic → anomaly-first** → Template 13
- **Tune dashboard time windows + SLOs** → Template 14
- **Stream a filtered subset of logs** → Template 15
- **SMS paging only (alarms-only)** → Template 16
- **Webhook / HTTPS endpoints (SNS HTTPS)** → Template 17
- **Least-privilege deploy (no Route 53 GetHostedZone)** → Template 18
- **Threat hunting / CI-only pack (+ Top-N + indexing)** → Template 19
- **Log hygiene (Data Protection + indexing) with anomaly detectors disabled** → Template 20
