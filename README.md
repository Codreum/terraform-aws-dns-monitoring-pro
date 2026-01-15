<p align="center">
  <a href="https://www.codreum.com">
    <img src="docs/brand/logo.png" alt="Codreum" width="200" />
  </a>
</p>

<p align="center">
  <a href="https://www.codreum.com">Website</a> •
  <a href="https://www.codreum.com/products.html#zone">Upgrade</a> •
  <a href="#quickstart">Quickstart</a>
</p>

# Codreum DNS Monitoring (NXDOMAIN)

Detect DNS misconfigurations fast by alerting on **NXDOMAIN spikes** using **AWS CloudWatch + Terraform**.

✅ Dashboards + alarms + anomaly detection  
✅ Works with **Route 53 hosted zone query logs** + **Resolver query logs (VPC)**  
✅ Top-N triage views (domain / qtype / edge / source)

This solution is for **NXDOMAIN signals only**. **Codreum Pro** adds broader DNS error metrics and investigation dashboards.

- **Deploy:** jump to [Quickstart](#quickstart)  
- **Website:** https://www.codreum.com  
- **Upgrade:** https://www.codreum.com/products.html#zone  

---

## Why NXDOMAIN matters

NXDOMAIN means “this name does not exist.” A spike is rarely random — it’s usually a signal that **something changed**.

Common causes:
- broken deployments (wrong domain, missing records, bad service discovery)
- misconfigured clients / endpoints (typos, outdated configs, DNS suffix issues)
- malware / beaconing attempts (random subdomains, DGA patterns)
- expired records or incorrect resolver paths

Why it’s valuable:
- **Fastest indicator of DNS regressions** (before app errors explode)
- Helps pinpoint **what** is failing and **who** is generating it (Top-N)
- Works for both **public hosted zones** and **private/VPC resolver** DNS

---

## Why AWS CloudWatch (in-account) instead of external DNS monitoring?

External checkers are useful, but they often miss the failures you actually care about:
- External monitors can only test **public DNS** and a small set of resolvers.
- They can’t see **your internal resolver traffic** (VPC Resolver logs).
- They typically miss **client-specific failures** and “partial outages” (only some subnets, only some clients, only some edges).

This module uses **your real DNS query logs** inside AWS:
- captures failures from **real production clients**
- supports **private/internal DNS** (VPC resolver queries)
- triages by **top offending domain / qtype / edge / source IP**
- avoids shipping DNS logs to third parties

> Privacy note: this module does **not** send DNS logs to Codreum. Everything stays inside your AWS account.

---

## What you get (Free)

✅ Included:
1. NXDOMAIN **count** alarm (Zone + VPC)
2. NXDOMAIN **rate (%)** alarm (Zone + VPC)
3. NXDOMAIN **Anomaly detection** alarms (count + rate)
4. CloudWatch dashboards:
   - Zone dashboard
   - VPC dashboard
   - Ops landing dashboard
5. Top-N triage views  
   - Zone: Top NXDOMAIN by domain/qtype/edge/source  
   - VPC: Top NXDOMAIN by qname/source
6. SNS integration: alarms publish to your provided SNS topic (`dns_alert_sns_arn`)

🚫 Not included (Free):
1. Additional DNS error metrics (SERVFAIL/REFUSED/etc.)
2. Expanded Contributor Insights packs and dashboards beyond NXDOMAIN
3. Licensing, enforcement, premium support / SLA (Pro)
4. Log group management (Pro)

| Capability | NXDOMAIN | Pro |
|---|:---:|:---:|
| NXDOMAIN static alarms + anomaly detection | ✅ | ✅ |
| NXDOMAIN Contributor Insights (Top-N rules) | ✅ | ✅ |
| NXDOMAIN dashboards (Zone/VPC baseline) | ✅ | ✅ |
| Additional DNS metrics + Contributor Insights packs (SERVFAIL/REFUSED/etc.) | ❌ | ✅ |
| Per zone metrics/Alarm/CI toggle | ❌ | ✅ |
| Per-zone metric dashboards (beyond NXDOMAIN) | ❌ | ✅ |
| Per-zone Top-N dashboards (expanded) | ❌ | ✅ |
| Built-in SNS wiring presets (Email / Slack / SMS) | ❌ | ✅ |
| Log group management | ❌ | ✅ |
| Multiple zone/VPC IDs in one deployment | ❌ | ✅ |
| Advanced dashboards (Ops landing / Investigation / Forensics) | ❌ | ✅ |
| Licensing & enforcement | ❌ | ✅ |
| Support / SLA | ❌ | ✅ |

---

## How it works (simple architecture)

This module:
1. reads from an existing CloudWatch Logs group containing DNS logs (`NX_log_group_name`)
2. creates:
   - Log metric filters → custom metrics in `Codreum/DNSCI`
   - CloudWatch alarms (static + rate % + anomaly)
   - Contributor Insights rules + Logs Insights widgets (Top-N triage)
   - Dashboards (zone, vpc, ops landing)
3. sends alarm notifications to your SNS topic (`dns_alert_sns_arn`)

---

## Prerequisites

1. Terraform >= 1.14
2. AWS provider >= 6.2
3. A CloudWatch Logs group already receiving DNS logs:
   - **Zone mode:** Route 53 hosted zone query logs (CLF-like fields include `hosted_zone_id`, `rcode`, `qname`, etc.)
   - **VPC mode:** JSON resolver query logs (fields include `vpc_id`, `rcode`, `srcaddr`, `query_name` / `qname`, etc.)
4. Region constraints (AWS limitation)
   - **Zone mode (`NX_zone_id`)**: Route 53 *public hosted zone* query logging requires the CloudWatch Logs log group in **`us-east-1` (US East / N. Virginia)**. Deploy this module in **`us-east-1`** for Zone mode. 
   - **VPC mode (`NX_vpc_id`)**: Resolver query logging is **regional**. Create the query logging configuration and destination (CloudWatch log group) in the **same region as the VPC**. If you have VPCs in multiple regions, deploy one module per region.
   - If you need both Zone + VPC monitoring across different regions, deploy **two module instances**: one in **`us-east-1`** for Zone mode, plus one per VPC region for Resolver mode.


---

## Configuration

Required:
- `prefix`
- `aws_region`
- `NX_log_group_name`
- `dns_alert_sns_arn`
- Provide at least one:
  - `NX_zone_id` (enables zone alarms/dashboards/widgets)
  - `NX_vpc_id` (enables vpc alarms/dashboards/widgets)

You can enable zone monitoring, VPC monitoring, or both.

---

## Quickstart

1) Ensure DNS query logs are flowing into CloudWatch Logs:
- Hosted zone query logs (CLF-like)
- Resolver query logs (JSON)

2) Copy/paste into `main.tf`:

```hcl
module "codreum_dns_NX" {
  source = "github.com/Codreum/terraform-aws-dns-monitoring-nxdomain//modules?ref=v0.1.0"

  prefix              = "acme-dev"
  aws_region          = "us-east-1"
  NX_log_group_name = "/aws/route53/resolver-query-logs"  # must match your CloudWatch log group name
  dns_alert_sns_arn   = "arn:aws:sns:us-east-1:123456789012:alerts" # change to your SNS ARN

  # Enable one or both:
  NX_vpc_id  = "vpc-0123456789abcdef0" # optional
  NX_zone_id = "Z123EXAMPLE"           # optional
}
```
You can also copy the main.tf file from example folder, and make the minimal edit
- replace  module source with "github.com/Codreum/terraform-aws-dns-monitoring-nxdomain//modules?ref=v0.1.0"
- Change NX_log_group_name , dns_alert_sns_arn, NX_vpc_id or/and NX_zone_id to your own resource
- Change the aws_region to the VPC Region, if you are using VPC Mode
- If using Zone mode, make sure aws_region = "us-east-1" (required by Route 53 query logging)

3. (optional) this module exports dashboard URLs, alarm ARNs, and metric names via Terraform outputs. If you want the output, paste this code too into your own main.tf
```hcl
output "dns_NX_enabled" {
  value = module.codreum_dns_NX.enabled
}

output "dns_NX_dashboards" {
  value = module.codreum_dns_NX.dashboards
}

output "dns_NX_alarms" {
  value = module.codreum_dns_NX.alarms
}

output "dns_NX_metrics" {
  value = module.codreum_dns_NX.metrics
}

output "dns_NX_ci_rules" {
  value = module.codreum_dns_NX.contributor_insights_rules
}
```

You can also copy the output.tf file from example folder

4. Deploy :

terraform init

terraform apply


## What you’ll see after deploy

After `terraform apply`, you’ll have CloudWatch **dashboards**, **alarms**, and **Contributor Insights** rules created in your AWS account.

> Tip: Open **CloudWatch → Dashboards** and search for your `prefix` (e.g., `acme-dev-*`).

### 1) Dashboards (Ops / Zone / VPC)

You’ll get an Ops landing page plus dashboards for the modes you enabled:

- **Ops landing**: quick links + “what to check first”
- **Zone dashboard** (if `NX_zone_id` is set): NXDOMAIN count, rate %, anomaly band, Top-N breakdowns
- **VPC dashboard** (if `NX_vpc_id` is set): NXDOMAIN count, rate %, anomaly band, Top-N by source/qname

![Dashboards](./screenshot/dashboard3.jpg)

![Dashboards](./screenshot/dashboard1.jpg)

![Dashboards](./screenshot/dashboard2.jpg)

**How to use**
- If alarms fire, start at **Ops landing**, then jump into **Zone/VPC** dashboard.
- Use **Top-N** tables to identify the top failing domains, qtype, edge, and source IPs.

---

### 2) Alarms (Count / Rate / Anomaly)

This module creates alarms for:
- **NXDOMAIN count** (static threshold)
- **NXDOMAIN rate (%)** (error rate)
- **Anomaly detection** on both count and rate

Alarms publish to your SNS topic (`dns_alert_sns_arn`).

![Alarms](./screenshot/alarm.jpg)

![Alarms](./screenshot/alarm2.jpg)

![Alarms](./screenshot/email_alert.jpg)

**What to check**
- **Count alarm**: sudden volume spike (often broken deploy / client loop)
- **Rate alarm**: NXDOMAIN becoming a larger share of total queries
- **Anomaly alarms**: unexpected behavior even if below static thresholds

---

### 3) Contributor Insights (Top-N triage)

Contributor Insights rules are used for “Top-N” analysis (fast triage):
- Zone: top NXDOMAIN by **qname / qtype / edge / source**
- VPC: top NXDOMAIN by **qname / source**

![Contributor Insights](./screenshot/CI1.jpg)

![Contributor Insights](./screenshot/CI2.jpg)

**How to use**
- Open **CloudWatch → Contributor Insights**
- Filter by your `prefix`
- Start with **Top qname** and **Top source** to quickly locate the cause



## Upgrade to Codreum Pro

Codreum Pro adds:
1. More DNS metrics (SERVFAIL/REFUSED/overall error, success rate, etc.)
2. More pre-built metric alarms, contributor insight packs
3. More dashboards with richer, opinionated investigation widgets
4. subscription management & support options
5. Multi-zone / multi-vpc support
6. Optional prebuilt alerting integrations (email / Slack / SMS) via SNS setup

Learn more: https://www.codreum.com/products.html#zone

## Costs (AWS billed)

This module creates CloudWatch resources that may incur AWS charges, depending on usage, region, and free tier.

- **Contributor Insights rules**: used for Top-N analysis (e.g., top NXDOMAIN domains/clients). Charged per rule and usage.
- **Custom metrics**: metric filters publish metrics under `Codreum/DNSCI` (e.g., `ZoneNXDOMAIN`, `VpcNXDOMAIN`). Custom metrics may be billed by AWS.
- **CloudWatch alarms**: static threshold, rate (%), and anomaly alarms may be billed by AWS.

See AWS pricing: https://aws.amazon.com/cloudwatch/pricing/

## Security & data
- This module does **not** send DNS logs to Codreum.
- All analysis happens inside your AWS account using CloudWatch Logs / Metrics / Contributor Insights.
- Alarm notifications are published only to your SNS topic.

## Limitations (Free)
- Designed for **one zone and/or one VPC** per deployment.
- Only NXDOMAIN signals are included.
- Assumes logs already exist in CloudWatch Logs.


## Support
- Free: community support via GitHub Issues  
- Pro: SLA-backed support options (link)

