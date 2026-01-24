module "dnsciz" {
  source  = "registry.codreum.com/codreum/dnsciz/aws"
  version = "1.0.0"

  prefix     = "acme-ci-only"
  aws_region = "us-east-1"

  license = {
    type       = "dnsciz"
    license_id = "lic_xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
    zone_ids   = ["Z123EXAMPLE1"]
  }

  subject_log_group_map = {
    "Z123EXAMPLE1" = "arn:aws:logs:us-east-1:123456789012:log-group:/aws/route53/zone-1"
  }

  # Per-zone dashboards (creates Zone + Zone Top-N)
  act_dashboard = ["Z123EXAMPLE1"]

  # CI-only families (Contributor Insights only; no CloudWatch custom metrics/alarms)
  act_metric = {
    "Z123EXAMPLE1" = [
      "qtype_profile",
      "high_value_qtype_profile",
      "rcode_profile",
      "proto_profile",
      "edns_behavior",

      "client_volume",
      "edge_imbalance",
      "client_edge_matrix",
      "qtype_edge_matrix",

      "suspicious_name_pattern",

      "error_qtype_profile",
      "error_high_value_qtype_profile",
      "error_client_volume",
      "error_edge_imbalance",
      "error_client_edge_matrix",
      "edns_error_profile"
    ]
  }

  # Optional: speed up Logs Insights queries with indexing
  log_index_override = {
    "/aws/route53/zone-1" = {
      enabled = true
      fields  = ["hosted_zone_id", "qname", "qtype", "rcode", "rip", "edge"]
    }
  }

  tags = { owner = "you", project = "dnsciz" }
}
