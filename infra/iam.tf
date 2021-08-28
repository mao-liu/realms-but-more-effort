data "aws_route53_zone" "aws" {
    name = "aws.ab-initio.me"
}

data "aws_iam_policy_document" "ec2_trust" {
    statement {
        actions = ["sts:AssumeRole"]

        principals {
            type        = "Service"
            identifiers = ["ec2.amazonaws.com"]
        }
    }
}

data "aws_iam_policy_document" "realm" {
    statement {
        sid = "SSM"
        actions = ["ssm:GetParameter*"]

        resources = [
            "arn:aws:ssm:${local.aws_region}:${local.aws_account}:parameter/realms/*"
        ]
    }

    statement {
        sid = "S3"
        actions = ["s3:*"]

        resources = [
            "${aws_s3_bucket.realms.arn}",
            "${aws_s3_bucket.realms.arn}/*"
        ]
    }

    statement {
        sid = "KMSEverything"
        actions = ["kms:*"]
        resources = ["*"]
    }

    statement {
        sid = "Route53"
        actions = ["route53:*"]
        resources = [
            "arn:aws:route53:::hostedzone/${data.aws_route53_zone.aws.zone_id}"
        ]
    }
}

resource "aws_iam_role" "realm" {
    name = "realm_ec2"

    assume_role_policy = data.aws_iam_policy_document.ec2_trust.json

    managed_policy_arns = [
        "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
    ]

    inline_policy {
        name = "realms"
        policy = data.aws_iam_policy_document.realm.json
    }


}

resource "aws_iam_instance_profile" "realm" {
    name = aws_iam_role.realm.name
    role = aws_iam_role.realm.name
}


resource "aws_iam_service_linked_role" "spot" {
    aws_service_name = "spot.amazonaws.com"
}
