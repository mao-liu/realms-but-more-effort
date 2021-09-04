locals {
    tags = {
        "Project" = "realms"
    }

    # spot prices retrieved from EC2 console, 2021-08
    spot_price_maximum = {
        "t3a.small":  0.008,    # on demand 0.0238
        "t3a.medium": 0.015,    # on demand 0.0475
        "t3a.large":  0.030,    # on demand 0.095
        "t3a.xlarge": 0.060,    # on demand 0.1901
    }

    instance_type = "t3a.small"

    r53_domain    = "aws.ab-initio.me"
    realms_api_domain_name = "api.realms.${local.r53_domain}"

    aws_region    = "ap-southeast-2"
    aws_account   = data.aws_caller_identity.current.account_id
}
