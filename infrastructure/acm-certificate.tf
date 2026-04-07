# ============================================================
# ACM TLS Certificate — app-dev.zamait.com
# ============================================================
# AWS Certificate Manager (ACM) issues a free, auto-renewing TLS
# certificate for the custom domain.  We use DNS validation so there
# is no manual email approval step.
#
# IMPORTANT — Region requirement:
#   AWS Amplify's custom-domain feature (like CloudFront) can only use
#   ACM certificates that live in us-east-1.  The provider.tf file
#   already sets this region, so no alias provider is needed here.
# ============================================================

resource "aws_acm_certificate" "app" {
  # The primary domain name for the certificate
  domain_name = "app-dev.zamait.com"

  # DNS validation is preferred over EMAIL validation because:
  #  - It does not require access to an email inbox
  #  - It can be fully automated
  #  - ACM auto-renews the cert as long as the CNAME record stays in DNS
  validation_method = "DNS"

  lifecycle {
    # Terraform creates the replacement certificate before destroying the
    # old one so there is zero downtime during cert renewals.
    create_before_destroy = true
  }
}

# ============================================================
# DNS Validation Record Details
# ============================================================
# ACM generates a unique CNAME record that proves you own the domain.
# You must add this record to your DNS provider (GoDaddy in this case)
# before ACM will issue the certificate.
#
# The record name and value are exposed as Terraform outputs so you
# can copy-paste them directly into GoDaddy's DNS management panel.
#
# Once the record is added, ACM validates automatically (usually within
# 5–30 minutes) and the certificate status changes to "Issued".
# ============================================================

# This resource instructs Terraform to wait until ACM has finished
# validating and the certificate reaches "Issued" status.
# It does NOT create any DNS records — you must add them manually in GoDaddy.
resource "aws_acm_certificate_validation" "app" {
  certificate_arn = aws_acm_certificate.app.arn

  # List every FQDN that needs a validation CNAME.
  # For a single-domain cert there is exactly one entry.
  validation_record_fqdns = [
    for dvo in aws_acm_certificate.app.domain_validation_options :
    dvo.resource_record_name
  ]

  # ACM validation can take up to 30 minutes after you add the CNAME.
  # Terraform will poll until the cert is issued or this timeout expires.
  timeouts {
    create = "45m"
  }
}
