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

  # Dashboards: fleet + investigation + per-zone for critical zones
  act_dashboard = ["opslanding", "investigation", "Z123EXAMPLE1", "Z123EXAMPLE2"]

  # Metrics + alarms + CI for incident triage
  act_metric = {
    "Z123EXAMPLE1" = [
      # Dashboard + core health
      "total", "success", "client_error", "nxdomain", "refused", "server_error", "proto_tcp", "edns_failure",
      # Helpful derived alarms (optional but recommended)
      "overall_error", "rare_error",
      # Guardrail
      "total_low",
      # CI packs (high-signal triage)
      "qtype_profile", "rcode_profile", "proto_profile", "edns_behavior",
      "client_volume", "edge_imbalance",
      "client_edge_matrix", "qtype_edge_matrix",
      # Error-focused variants (optional)
      "error_qtype_profile", "error_client_volume", "error_edge_imbalance", "error_client_edge_matrix"
    ]
    "Z123EXAMPLE2" = [
      "total", "success", "client_error", "nxdomain", "refused", "server_error",
      "proto_tcp", "edns_failure", "overall_error", "rare_error", "total_low",
      "qtype_profile", "rcode_profile", "client_volume", "edge_imbalance"
    ]
    "Z123EXAMPLE3" = [
      # Smaller / less critical zones can run a lighter set
      "total", "success", "client_error", "nxdomain", "server_error", "refused", "total_low"
    ]
  }

  tags = { owner = "you", project = "dnsciz" }
}
