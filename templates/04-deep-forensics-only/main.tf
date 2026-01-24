module "dnsciz" {
  source  = "registry.codreum.com/codreum/dnsciz/aws"
  version = "1.0.0"

  prefix     = "acme-prod"
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

  act_dashboard = ["forensic"]

  act_metric = {
    "Z123EXAMPLE1" = ["total", "client_error", "nxdomain", "refused", "server_error", "proto_tcp"]
    "Z123EXAMPLE2" = ["total", "client_error", "nxdomain", "refused", "server_error", "proto_tcp"]
  }

  tags = { owner = "you", project = "dnsciz" }
}
