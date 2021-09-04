data "aws_route53_zone" "aws" {
    name = local.r53_domain
}

data "aws_iam_policy_document" "ec2_trust" {
    statement {
        actions = ["sts:AssumeRole"]

        principals {
            type        = "Service"
            identifiers = ["ec2.amazonaws.com"]
        }
    }
    statement {
        actions = ["sts:AssumeRole"]

        principals {
            type        = "Service"
            identifiers = ["lambda.amazonaws.com"]
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
        actions = [
            "kms:Encrypt",
            "kms:Decrypt",
            "kms:ReEncrypt*",
            "kms:GenerateDataKey*",
            "kms:DescribeKey"
        ]
        resources = ["*"]
    }

    statement {
        sid = "Route53"
        actions = ["route53:*"]
        resources = [
            "arn:aws:route53:::hostedzone/${data.aws_route53_zone.aws.zone_id}"
        ]
    }

    statement {
        sid = "ASGModify"
        actions = ["autoscaling:*"]
        resources = ["*"]
        condition {
            test     = "StringEquals"
            variable = "aws:ResourceTag/Project"
            values   = [local.tags["Project"]]
        }
    }

    statement {
        sid = "ASGRead"
        actions = [
            "autoscaling:Describe*",
            "ec2:Describe*",
            "ec2:Get*"
        ]
        resources = ["*"]
    }
}

resource "aws_iam_role" "realm" {
    name = "realm_ec2"

    assume_role_policy = data.aws_iam_policy_document.ec2_trust.json

    managed_policy_arns = [
        "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
        "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
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
