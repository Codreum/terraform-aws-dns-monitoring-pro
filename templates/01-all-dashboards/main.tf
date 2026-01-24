module "dnsciz" {
  source  = "registry.codreum.com/codreum/dnsciz/aws"
  version = "1.0.0"

  prefix     = "acme-prod"
  aws_region = "us-east-1"

  license = {
    type       = "dnsciz"
    license_id = "lic_xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
    zone_ids   = ["Z123EXAMPLE1", "Z123EXAMPLE2", "Z123EXAMPLE3"]
  }

  subject_log_group_map = {
    "Z123EXAMPLE1" = "arn:aws:logs:us-east-1:123456789012:log-group:/aws/route53/zone-1"
    "Z123EXAMPLE2" = "arn:aws:logs:us-east-1:123456789012:log-group:/aws/route53/zone-2"
    "Z123EXAMPLE3" = "arn:aws:logs:us-east-1:123456789012:log-group:/aws/route53/zone-3"
  }

  # Dashboards: all global dashboards + per-zone dashboards for each ZoneId
  act_dashboard = ["opslanding", "investigation", "forensic", "Z123EXAMPLE1", "Z123EXAMPLE2", "Z123EXAMPLE3"]

  # (Optional) Dashboard lookbacks / tile periods (defaults shown)
  # dns_primary_lookback           = "-PT3H"
  # dns_deep_forensics_lookback    = "-PT6H"
  # dns_sli_tile_period_seconds    = 300
  # dns_topn_bucket_period_seconds = 300

  # Metrics: full dashboard coverage per zone
  act_metric = {
    "Z123EXAMPLE1" = ["total", "success", "client_error", "nxdomain", "refused", "server_error", "proto_tcp", "edns_failure"]
    "Z123EXAMPLE2" = ["total", "success", "client_error", "nxdomain", "refused", "server_error", "proto_tcp", "edns_failure"]
    "Z123EXAMPLE3" = ["total", "success", "client_error", "nxdomain", "refused", "server_error", "proto_tcp", "edns_failure"]
  }

  tags = { owner = "you", project = "dnsciz" }
}
