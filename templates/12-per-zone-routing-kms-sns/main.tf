module "dnsciz" {
  source  = "registry.codreum.com/codreum/dnsciz/aws"
  version = "1.0.0"

  prefix     = "acme-routing"
  aws_region = "us-east-1"

  license = {
    type       = "dnsciz"
    license_id = "lic_xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
    zone_ids   = ["Z123CRIT", "Z123STD1", "Z123STD2"]
  }

  subject_log_group_map = {
    "Z123CRIT" = "arn:aws:logs:us-east-1:123456789012:log-group:/aws/route53/crit-zone"
    "Z123STD1" = "arn:aws:logs:us-east-1:123456789012:log-group:/aws/route53/std-zone-1"
    "Z123STD2" = "arn:aws:logs:us-east-1:123456789012:log-group:/aws/route53/std-zone-2"
  }

  # Encrypt the default topic
  sns_kms_master_key_id = "alias/aws/sns" # or your CMK ARN

  # Route critical zone alarms to an existing SNS topic (your pager integration)
  subject_sns_topic_map = {
    "Z123CRIT" = "arn:aws:sns:us-east-1:123456789012:acme-critical-paging"
  }

  act_dashboard = ["opslanding", "investigation", "Z123CRIT", "Z123STD1", "Z123STD2"]

  act_metric = {
    "Z123CRIT" = ["total", "success", "client_error", "nxdomain", "refused", "server_error", "proto_tcp", "edns_failure", "total_low", "overall_error", "rare_error"]
    "Z123STD1" = ["total", "success", "client_error", "nxdomain", "server_error", "refused", "total_low"]
    "Z123STD2" = ["total", "success", "client_error", "nxdomain", "server_error", "refused", "total_low"]
  }

  # Default topic subscriptions (applies to zones not overridden in subject_sns_topic_map)
  dns_alert_emails = ["dns-ops@example.com"]

  enable_slack_notifications = true
  slack_workspace_id         = "TXXXXXXXXXX"
  slack_channel_id           = "CXXXXXXXXXX"

  tags = { owner = "you", project = "dnsciz" }
}

