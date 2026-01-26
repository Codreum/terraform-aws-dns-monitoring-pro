module "dnsciz" {
  source  = "registry.codreum.com/codreum/dnsciz/aws"
  version = "1.0.0"

  prefix     = "acme-ux"
  aws_region = "us-east-1"

  license = {
    type       = "dnsciz"
    license_id = "lic_xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
    zone_ids   = ["Z123EXAMPLE1", "Z123EXAMPLE2"]
  }

  subject_log_group_map = {
    "Z123EXAMPLE1" = "arn:aws:logs:us-east-1:123456789012:log-group:/aws/route53/zone-1"
    "Z123EXAMPLE2" = "arn:aws:logs:us-east-1:123456789012:log-group:/aws/route53/zone-2"
  }

  act_dashboard = ["opslanding", "investigation", "forensic", "Z123EXAMPLE1", "Z123EXAMPLE2"]

  # Default dashboard time windows (ISO-8601 durations)
  dns_primary_lookback        = "-PT1H"  # Landing/Investigations/per-zone
  dns_deep_forensics_lookback = "-PT12H" # Forensics

  # “last Xm” behavior: show the most recent bucket of this fixed period
  dns_sli_tile_period_seconds    = 60  # last 1m
  dns_topn_bucket_period_seconds = 120 # last 2m

  # Top-N sizing (applies to tables)
  dns_topn = 25

  # Optional runbook link rendered into dashboard header text widgets
  dns_runbook_url = "https://example.com/runbooks/dns"

  # Optional SLO overlays (percent values 0-100)
  dns_slo_config = {
    success_pct       = 99.95
    overall_error_pct = 0.10
    non_nx_error_pct  = 0.02
    tcp_pct_max       = 5
    edns_none_pct_max = 2
    edns_bad_pct_max  = 0.5
  }

  act_metric = {
    "Z123EXAMPLE1" = ["total", "success", "client_error", "nxdomain", "refused", "server_error", "proto_tcp", "edns_failure"]
    "Z123EXAMPLE2" = ["total", "success", "client_error", "nxdomain", "refused", "server_error", "proto_tcp", "edns_failure"]
  }

  tags = { owner = "you", project = "dnsciz" }
}
