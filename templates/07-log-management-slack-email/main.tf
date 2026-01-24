module "dnsciz" {
  source  = "registry.codreum.com/codreum/dnsciz/aws"
  version = "1.0.0"

  prefix     = "acme-prod"
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

  # Keep dashboards fully populated for this zone
  act_metric = {
    "Z123EXAMPLE1" = ["total", "success", "client_error", "nxdomain", "refused", "server_error", "proto_tcp", "edns_failure", "total_low"]
  }

  ########################################
  # DNS alerting destinations
  ########################################
  dns_alert_emails = ["oncall@example.com"]

  enable_slack_notifications = true
  slack_workspace_id         = "TXXXXXXXXXX"
  slack_channel_id           = "CXXXXXXXXXX"

  ########################################
  # Log management (opt-in)
  ########################################

  # CloudWatch Logs Data Protection (example: audit/de-identify IPs/emails)
  log_data_protection_override = {
    "/aws/route53/zone-1" = {
      enabled = true
      managed_identifiers = [
        "arn:aws:dataprotection::aws:data-identifier/EmailAddress",
        "arn:aws:dataprotection::aws:data-identifier/IpAddress"
      ]
    }
  }

  # CloudWatch Logs anomaly detector
  log_anomaly_override = {
    "/aws/route53/zone-1" = { enabled = true }
  }

  # Log field indexing (use module defaults)
  log_index_override = {
    "/aws/route53/zone-1" = { enabled = true }
  }

  tags = { owner = "you", project = "dnsciz" }
}
