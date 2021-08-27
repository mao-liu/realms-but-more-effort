terraform {
    backend "remote" {
        hostname     = "app.terraform.io"
        organization = "mao-liu"

        workspaces {
            name = "realms-game-au"
        }
    }

    required_providers {
        aws = {
            source  = "hashicorp/aws"
            version = "~> 3.0"
        }
    }
}

provider "aws" {
    region = "ap-southeast-2"

    default_tags {
        tags = {
            Project = "realms"
        }
    }
}

data "aws_caller_identity" "current" {}

output "account_id" {
    value = data.aws_caller_identity.current.account_id
}

output "caller_arn" {
    value = data.aws_caller_identity.current.arn
}

output "caller_user" {
    value = data.aws_caller_identity.current.user_id
}
