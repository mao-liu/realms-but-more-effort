data "aws_route53_zone" "aws" {
    name = local.r53_domain
}

resource "aws_acm_certificate" "api-realms" {
  domain_name       = local.realms_api_domain_name
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "api-realms-cert" {
  for_each = {
    for dvo in aws_acm_certificate.example.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.aws.zone_id
}

resource "aws_acm_certificate_validation" "api-realms" {
  certificate_arn         = aws_acm_certificate.api-realms.arn
  validation_record_fqdns = [for record in aws_route53_record.example : record.fqdn]
}

resource "aws_apigatewayv2_domain_name" "api-realms" {
    domain_name = local.realms_api_domain_name

    domain_name_configuration {
        certificate_arn = aws_acm_certificate.api-realms.arn
        endpoint_type   = "REGIONAL"
        security_policy = "TLS_1_2"
    }
}

resource "aws_route53_record" "api-realms" {
    name    = aws_apigatewayv2_domain_name.api-realms.domain_name
    type    = "A"
    zone_id = data.aws_route53_zone.aws.zone_id

    alias {
        name    = aws_apigatewayv2_domain_name.api-realms.domain_name_configuration[0].target_domain_name
        zone_id = aws_apigatewayv2_domain_name.api-realms.domain_name_configuration[0].hosted_zone_id
        evaluate_target_health = false
    }
}
