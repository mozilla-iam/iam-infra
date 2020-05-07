resource "aws_ses_domain_identity" "main" {
  domain = var.ses-domain
}

resource "aws_ses_domain_identity_verification" "main" {
  domain     = aws_ses_domain_identity.main.id
  depends_on = [aws_route53_record.ses_verification]
}

resource "aws_route53_record" "ses_verification" {
  zone_id = data.aws_route53_zone.sso_allizom_org.zone_id
  name    = "_amazonses.${aws_ses_domain_identity.main.id}"
  type    = "TXT"
  ttl     = "600"
  records = [aws_ses_domain_identity.main.verification_token]
}

resource "aws_ses_domain_dkim" "main" {
  domain = aws_ses_domain_identity.main.domain
}

resource "aws_route53_record" "dkim" {
  count   = 3
  zone_id = data.aws_route53_zone.sso_allizom_org.zone_id
  name = format(
    "%s._domainkey.%s",
    element(aws_ses_domain_dkim.main.dkim_tokens, count.index),
    aws_ses_domain_identity.main.domain,
  )
  type    = "CNAME"
  ttl     = "600"
  records = ["${element(aws_ses_domain_dkim.main.dkim_tokens, count.index)}.dkim.amazonses.com"]
}

# SPF validaton record
#resource "aws_route53_record" "spf_mail_from" {
#  zone_id = data.aws_route53_zone.sso_allizom_org.zone_id
#  name    = aws_ses_domain_mail_from.main.mail_from_domain
#  type    = "TXT"
#  ttl     = "600"
#  records = ["v=spf1 include:amazonses.com -all"]
#}

resource "aws_route53_record" "spf_domain" {
  zone_id = data.aws_route53_zone.sso_allizom_org.zone_id
  name    = aws_ses_domain_identity.main.domain
  type    = "TXT"
  ttl     = "600"
  records = ["v=spf1 include:amazonses.com -all"]
}

resource "aws_route53_record" "mx_send_mail_from" {
  zone_id = data.aws_route53_zone.sso_allizom_org.zone_id
  name    = aws_ses_domain_identity.main.domain
  type    = "MX"
  ttl     = "600"
  records = ["10 feedback-smtp.${var.region}.amazonses.com"]
}

# DMARC TXT Record
resource "aws_route53_record" "txt_dmarc" {
  zone_id = data.aws_route53_zone.sso_allizom_org.zone_id
  name    = "_dmarc.${aws_ses_domain_identity.main.domain}"
  type    = "TXT"
  ttl     = "600"
  records = ["v=DMARC1; p=reject;rua=mailto:postmaster@${aws_ses_domain_identity.main.domain};"]
}

