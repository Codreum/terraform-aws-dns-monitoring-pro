module "dnsciz" {
  source  = "registry.codreum.com/codreum/dnsciz/aws"
  version = "1.0.0"

  prefix     = "acme-rollout"
  aws_region = "us-east-1"

  license = {
    type       = "dnsciz"
    license_id = "lic_xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
    zone_ids   = ["Z123CANARY", "Z123NEXT1", "Z123NEXT2"]
  }

  subject_log_group_map = {
    "Z123CANARY" = "arn:aws:logs:us-east-1:123456789012:log-group:/aws/route53/canary-zone"
    "Z123NEXT1"  = "arn:aws:logs:us-east-1:123456789012:log-group:/aws/route53/next-zone-1"
    "Z123NEXT2"  = "arn:aws:logs:us-east-1:123456789012:log-group:/aws/route53/next-zone-2"
  }

  # Create dashboards for everyone from day 1
  act_dashboard = ["opslanding", "investigation", "forensic", "Z123CANARY", "Z123NEXT1", "Z123NEXT2"]

  # Canary has full widget coverage; other zones intentionally omitted (not enabled yet).
  act_metric = {
    "Z123CANARY" = ["total", "success", "client_error", "nxdomain", "refused", "server_error", "proto_tcp", "edns_failure", "total_low"]
  }

  tags = { owner = "you", project = "dnsciz" }
}
