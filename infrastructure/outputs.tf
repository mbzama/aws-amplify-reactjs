# ============================================================
# Outputs
# ============================================================
# These values are printed after every successful `terraform apply`
# and are also retrievable with `terraform output`.
# ============================================================

# ------------------------------------------------------------
# Amplify
# ------------------------------------------------------------

output "amplify_app_id" {
  description = "The unique Amplify application ID (e.g. d1abc2def3ghi). Used to construct console URLs and as an identifier in other AWS resources."
  value       = aws_amplify_app.app.id
}

output "amplify_default_domain" {
  description = "The auto-generated Amplify domain (e.g. main.d1abc2def3ghi.amplifyapp.com). Useful for testing before the custom domain is fully propagated."
  value       = "${aws_amplify_branch.main.branch_name}.${aws_amplify_app.app.default_domain}"
}

output "amplify_app_url" {
  description = "The live URL of the deployed application on the custom domain."
  value       = "https://app-dev.zamait.com"
}

# ------------------------------------------------------------
# ACM Certificate
# ------------------------------------------------------------

output "acm_certificate_arn" {
  description = "ARN of the ACM certificate for app-dev.zamait.com. Reference this in other AWS resources (e.g. CloudFront distributions) that require the cert."
  value       = aws_acm_certificate.app.arn
}

output "acm_validation_cname_name" {
  description = "The CNAME record NAME you must add to GoDaddy DNS to allow ACM to validate domain ownership. Copy this value exactly — it includes a trailing dot."
  value = tolist([
    for dvo in aws_acm_certificate.app.domain_validation_options :
    dvo.resource_record_name
  ])[0]
}

output "acm_validation_cname_value" {
  description = "The CNAME record VALUE (target) you must add to GoDaddy DNS alongside the CNAME name above. Copy this value exactly — it includes a trailing dot."
  value = tolist([
    for dvo in aws_acm_certificate.app.domain_validation_options :
    dvo.resource_record_value
  ])[0]
}

output "acm_validation_instructions" {
  description = "Human-readable reminder of what to do with the CNAME outputs above."
  value       = "Add a CNAME record in GoDaddy: Name = acm_validation_cname_name (strip the trailing dot and the .zamait.com suffix if GoDaddy adds the root domain automatically), Value = acm_validation_cname_value (strip the trailing dot)."
}
