variable "api_key" {
    type        = string
    description = "API key used for interacting with api.realms.aws.ab-initio.me"
}

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
        "t4g.small":  0.007,    # on demand 0.0212
        "t4g.medium": 0.013,    # on demand 0.0424
        "t4g.large":  0.026,    # on demand 0.0848
        "t4g.xlarge": 0.052,    # on demand 0.1696
    }

    instance_type = "t3a.medium"

    r53_domain    = "aws.ab-initio.me"
    realms_api_domain_name = "api.realms.${local.r53_domain}"

    aws_region    = "ap-southeast-2"
    aws_account   = data.aws_caller_identity.current.account_id
}
