module "dnsciz" {
  source  = "registry.codreum.com/codreum/dnsciz/aws"
  version = "1.0.0"

  prefix     = "acme-log-hygiene"
  aws_region = "us-east-1"

  license = {
    type       = "dnsciz"
    license_id = "lic_xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
    zone_ids   = ["Z123EXAMPLE1"]
  }

  subject_log_group_map = {
    "Z123EXAMPLE1" = "arn:aws:logs:us-east-1:123456789012:log-group:/aws/route53/zone-1"
  }

  act_dashboard = ["opslanding", "investigation", "Z123EXAMPLE1"]

  act_metric = {
    "Z123EXAMPLE1" = ["total", "success", "client_error", "nxdomain", "refused", "server_error", "proto_tcp", "edns_failure", "total_low"]
  }

  # Log Data Protection (managed identifiers)
  log_data_protection_override = {
    "/aws/route53/zone-1" = {
      enabled = true
      managed_identifiers = [
        "arn:aws:dataprotection::aws:data-identifier/IpAddress",
        "arn:aws:dataprotection::aws:data-identifier/EmailAddress"
      ]

      # Optional findings config
      findings_log_group_name    = "/aws/route53/dp-findings"
      findings_retention_in_days = 14
      # findings_kms_key_id      = "arn:aws:kms:us-east-1:123456789012:key/..."
    }
  }

  # Log field indexing for faster Insights queries
  log_index_override = {
    "/aws/route53/zone-1" = {
      enabled = true
      fields  = ["hosted_zone_id", "qname", "qtype", "rcode", "rip", "edge"]
    }
  }

  # Kill-switch for Log Anomaly Detectors
  log_anomaly_detector_enabled = false

  tags = { owner = "you", project = "dnsciz" }
}
