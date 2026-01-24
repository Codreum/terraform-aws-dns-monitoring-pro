module "dnsciz" {
  source  = "registry.codreum.com/codreum/dnsciz/aws"
  version = "1.0.0"

  prefix     = "acme-forward"
  aws_region = "us-east-1"

  license = {
    type       = "dnsciz"
    license_id = "lic_xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
    zone_ids   = ["Z123EXAMPLE1"]
  }

  subject_log_group_map = {
    "Z123EXAMPLE1" = "arn:aws:logs:us-east-1:123456789012:log-group:/aws/route53/zone-1"
  }

  # Minimal metrics (optional; not required for forwarding)
  act_metric = {
    "Z123EXAMPLE1" = ["total", "nxdomain", "client_error", "server_error", "refused"]
  }

  # Forward subset of logs
  log_subscription_overrides = {
    "/aws/route53/zone-1" = [
      {
        name            = "to-firehose-errors"
        enabled         = true
        destination_arn = "arn:aws:firehose:us-east-1:123456789012:deliverystream/acme-dns-errors"
        filter_pattern  = "SERVFAIL ?REFUSED ?NXDOMAIN" # placeholder
        role_arn        = "arn:aws:iam::123456789012:role/FirehosePutRole"
      }
    ]
  }

  tags = { owner = "you", project = "dnsciz" }
}
