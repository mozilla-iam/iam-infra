# Instead of copying global addresses over, let's define some of our DNS
# infrastructure here. That way we only need to copy over the NS records to AWS
# Route53 rather than needing to also copy over static IPs.
resource "google_dns_managed_zone" "gcp_iam_auth0" {
  name     = "gcp-iam-auth0-sso-mozilla-com"
  dns_name = "gcp-iam-auth0.sso.mozilla.com."
  dnssec_config {
    state = "on"
  }
  visibility = "public"
}

# We'll need the following outputs to be copied over to our AWS Hosted Zone.

output "gcp_iam_auth0_dns_zone_ns_records" {
  value = google_dns_managed_zone.gcp_iam_auth0.name_servers
}

output "gcp_iam_auth0_dns_zone_name" {
  value = google_dns_managed_zone.gcp_iam_auth0.name
}

output "gcp_iam_auth0_dns_zone_id" {
  value = google_dns_managed_zone.gcp_iam_auth0.id
}
