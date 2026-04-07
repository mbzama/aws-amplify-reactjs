# ============================================================
# AWS Amplify Application
# ============================================================
# This file creates:
#   1. The Amplify app connected to your GitHub repository
#   2. A "main" branch with automatic deployments enabled
#   3. A custom domain pointing to app-dev.zamait.com
# ============================================================

# ------------------------------------------------------------
# 1. Amplify App
# ------------------------------------------------------------
resource "aws_amplify_app" "app" {
  name        = var.app_name
  repository  = var.github_repository
  oauth_token = var.github_oauth_token

  # Use the amplify.yml checked into the repository root instead of
  # specifying build commands inline.  Any change to the build process
  # only requires a Git commit — no Terraform apply needed.
  build_spec = file("${path.module}/../amplify.yml")

  # Redirect all 404 responses to index.html so that React Router's
  # client-side routing works correctly on page refresh or direct URL access.
  custom_rule {
    source = "/<*>"
    target = "/index.html"
    status = "404-200"
  }

  # Rewrite rule that normalises clean URLs (removes the .html extension)
  custom_rule {
    source = "</^[^.]+$|\\.(?!(css|gif|ico|jpg|js|png|txt|svg|woff|woff2|ttf|map|json)$)([^.]+$)/>"
    target = "/index.html"
    status = "200"
  }

  # Environment variables available to the build container.
  # Add any REACT_APP_* variables your app needs here.
  environment_variables = {
    REACT_APP_ENV = "dev"
  }
}

# ------------------------------------------------------------
# 2. Branch — main
# ------------------------------------------------------------
resource "aws_amplify_branch" "main" {
  app_id      = aws_amplify_app.app.id
  branch_name = "main"

  # Trigger a new Amplify build automatically on every push to this branch
  enable_auto_build = true

  # Mark this branch as the "production" branch in the Amplify Console UI
  framework = "React"
  stage     = "PRODUCTION"

  # Inherit environment variables defined on the parent app.
  # Branch-level variables override app-level ones if the key matches.
  environment_variables = {}
}

# ------------------------------------------------------------
# 3. Custom Domain — app-dev.zamait.com
# ------------------------------------------------------------
# This resource tells Amplify to serve traffic for the custom domain
# and wire it to the Amplify CDN.  Amplify will also create its own
# DNS validation records internally; the ACM certificate you provisioned
# in acm-certificate.tf provides the TLS layer.
#
# NOTE: After applying, Amplify will show additional CNAME records in the
# Amplify Console (under "Domain management") that you must also add to
# GoDaddy so that app-dev.zamait.com resolves to Amplify's CDN.
# ------------------------------------------------------------
resource "aws_amplify_domain_association" "app" {
  app_id      = aws_amplify_app.app.id
  domain_name = "app-dev.zamait.com"

  # Map the root of the custom domain to the main branch
  sub_domain {
    # An empty prefix means the apex/root domain (app-dev.zamait.com)
    branch_name = aws_amplify_branch.main.branch_name
    prefix      = ""
  }

  # Amplify requires the ACM certificate to be issued before it can
  # activate the custom domain.  Depend on the validation resource so
  # Terraform waits for the cert to reach "Issued" status first.
  depends_on = [aws_acm_certificate_validation.app]
}
