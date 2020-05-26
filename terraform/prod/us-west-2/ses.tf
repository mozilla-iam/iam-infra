# SES Configuration for prod environment
resource "aws_ses_domain_identity" "prod" {
  domain = var.ses-domain-prod
}

resource "aws_ses_domain_identity_verification" "prod" {
  domain     = aws_ses_domain_identity.prod.id
  depends_on = [aws_route53_record.ses_verification]
}

resource "aws_route53_record" "prod_ses_verification" {
  zone_id = data.aws_route53_zone.people_mozilla_org.zone_id
  name    = "_amazonses.${aws_ses_domain_identity.prod.id}"
  type    = "TXT"
  ttl     = "600"
  records = [aws_ses_domain_identity.prod.verification_token]
}

resource "aws_ses_domain_dkim" "prod" {
  domain = aws_ses_domain_identity.prod.domain
}

resource "aws_route53_record" "prod_dkim" {
  count   = 3
  zone_id = data.aws_route53_zone.people_mozilla_org.zone_id
  name = format(
    "%s._domainkey.%s",
    element(aws_ses_domain_dkim.prod.dkim_tokens, count.index),
    aws_ses_domain_identity.prod.domain,
  )
  type    = "CNAME"
  ttl     = "600"
  records = ["${element(aws_ses_domain_dkim.prod.dkim_tokens, count.index)}.dkim.amazonses.com"]
}

resource "aws_route53_record" "prod_spf_domain" {
  zone_id = data.aws_route53_zone.people_mozilla_org.zone_id
  name    = aws_ses_domain_identity.prod.domain
  type    = "TXT"
  ttl     = "600"
  records = ["v=spf1 include:amazonses.com -all"]
}

resource "aws_route53_record" "prod_mx_send_mail_from" {
  zone_id = data.aws_route53_zone.people_mozilla_org.zone_id
  name    = aws_ses_domain_identity.prod.domain
  type    = "MX"
  ttl     = "600"
  records = ["10 feedback-smtp.${var.region}.amazonses.com"]
}

# DMARC TXT Record
resource "aws_route53_record" "prod_txt_dmarc" {
  zone_id = data.aws_route53_zone.people_mozilla_org.zone_id
  name    = "_dmarc.${aws_ses_domain_identity.prod.domain}"
  type    = "TXT"
  ttl     = "600"
  records = ["v=DMARC1; p=reject;rua=mailto:postmaster@${aws_ses_domain_identity.prod.domain};"]
}

# SES Configuration for test environment
resource "aws_ses_domain_identity" "test" {
  domain = var.ses-domain-test
}

resource "aws_ses_domain_identity_verification" "test" {
  domain     = aws_ses_domain_identity.test.id
  depends_on = [aws_route53_record.ses_verification]
}

resource "aws_route53_record" "ses_verification" {
  zone_id = data.aws_route53_zone.sso_allizom_org.zone_id
  name    = "_amazonses.${aws_ses_domain_identity.test.id}"
  type    = "TXT"
  ttl     = "600"
  records = [aws_ses_domain_identity.test.verification_token]
}

resource "aws_ses_domain_dkim" "test" {
  domain = aws_ses_domain_identity.test.domain
}

resource "aws_route53_record" "dkim" {
  count   = 3
  zone_id = data.aws_route53_zone.sso_allizom_org.zone_id
  name = format(
    "%s._domainkey.%s",
    element(aws_ses_domain_dkim.test.dkim_tokens, count.index),
    aws_ses_domain_identity.test.domain,
  )
  type    = "CNAME"
  ttl     = "600"
  records = ["${element(aws_ses_domain_dkim.test.dkim_tokens, count.index)}.dkim.amazonses.com"]
}

resource "aws_route53_record" "spf_domain" {
  zone_id = data.aws_route53_zone.sso_allizom_org.zone_id
  name    = aws_ses_domain_identity.test.domain
  type    = "TXT"
  ttl     = "600"
  records = ["v=spf1 include:amazonses.com -all"]
}

resource "aws_route53_record" "mx_send_mail_from" {
  zone_id = data.aws_route53_zone.sso_allizom_org.zone_id
  name    = aws_ses_domain_identity.test.domain
  type    = "MX"
  ttl     = "600"
  records = ["10 feedback-smtp.${var.region}.amazonses.com"]
}

# DMARC TXT Record
resource "aws_route53_record" "txt_dmarc" {
  zone_id = data.aws_route53_zone.sso_allizom_org.zone_id
  name    = "_dmarc.${aws_ses_domain_identity.test.domain}"
  type    = "TXT"
  ttl     = "600"
  records = ["v=DMARC1; p=reject;rua=mailto:postmaster@${aws_ses_domain_identity.test.domain};"]
}
