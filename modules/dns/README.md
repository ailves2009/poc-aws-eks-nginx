# modules/route53-hosted-zone

Simple module to create a public Route53 hosted zone and return its ID and name servers.

Variables:
- `zone_name` (string) – domain name, default `poc-plt.ailves.xyz`
- `tags` (map) – tags for the zone
- `comment` (string) – optional comment
- `force_destroy` (bool) – allow destroying zone with records

Outputs:
- `zone_id`, `name_servers`, `zone_arn`

Usage example (Terraform module):

```
module "zone" {
  source    = "../../modules/route53-hosted-zone"
  zone_name = "poc-plt.ailves.xyz"
  tags = {
    Environment = "plt"
    Client      = "poc"
  }
}

output "ns" {
  value = module.zone.name_servers
}
```
