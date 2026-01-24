module "dnsciz" {
  source  = "registry.codreum.com/codreum/dnsciz/aws"
  version = "1.0.0"

  prefix     = "acme-topn-only"
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

  # Per-zone dashboards (creates Zone + Zone Top‑N)
  act_dashboard = ["Z123EXAMPLE1", "Z123EXAMPLE2"]

  # No metrics/alarms/CI created (expected: metric widgets show No data)
  act_metric = {}

  tags = { owner = "you", project = "dnsciz" }
}
