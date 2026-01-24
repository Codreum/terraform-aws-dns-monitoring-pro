module "dnsciz" {
  source  = "registry.codreum.com/codreum/dnsciz/aws"
  version = "1.0.0"

  prefix     = "acme-anom"
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
    "Z123EXAMPLE1" = [
      # Base metrics
      "total", "success", "client_error", "nxdomain", "server_error", "refused", "proto_tcp", "edns_failure", "total_low",

      # Count anomaly alarms
      "total_anom", "nxdomain_anom", "client_error_anom", "server_error_anom", "refused_anom",

      # Rate/percent anomaly alarms
      "success_rate_anom", "client_error_rate_anom", "nxdomain_rate_anom",
      "server_error_rate_anom", "refused_rate_anom",
      "proto_tcp_rate_anom", "edns_none_rate_anom", "edns_bad_rate_anom"
    ]
  }

  # Optional: tune alarm behavior per metric (names are fixed)
  metric_override = {
    "Z123EXAMPLE1" = {
      # Focus on anomaly actions; disable static threshold actions if desired
      nxdomain_rate = {
        anomaly_eval_periods    = 3
        anomaly_band_width      = 2.5
        static_actions_enabled  = false
        anomaly_actions_enabled = true
      }
      success_rate = {
        anomaly_eval_periods    = 3
        anomaly_band_width      = 2.0
        static_actions_enabled  = false
        anomaly_actions_enabled = true
      }
    }
  }

  dns_alert_emails = ["oncall@example.com"]

  enable_slack_notifications = true
  slack_workspace_id         = "TXXXXXXXXXX"
  slack_channel_id           = "CXXXXXXXXXX"

  tags = { owner = "you", project = "dnsciz" }
}
