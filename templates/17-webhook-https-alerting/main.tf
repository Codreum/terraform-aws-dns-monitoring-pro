module "dnsciz" {
  source  = "registry.codreum.com/codreum/dnsciz/aws"
  version = "1.0.0"

  prefix     = "acme-webhook"
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
      "total", "total_low",
      "success",
      "client_error", "nxdomain", "refused", "server_error",
      "proto_tcp", "edns_failure",
      "overall_error", "rare_error"
    ]
  }

  # SNS topic encryption (optional)
  sns_kms_master_key_id = "alias/aws/sns" # or your CMK ARN

  # SNS → HTTPS endpoint subscriptions
  dns_alert_https_endpoints = [
    "https://hooks.example.com/sns/dns-oncall"
  ]

  # Slack intentionally disabled in this template
  enable_slack_notifications = false

  tags = { owner = "you", project = "dnsciz" }
}
