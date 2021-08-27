data "aws_ssm_parameter" "ami_id" {
    name = "/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2"
}

resource "aws_security_group" "minecraft_ingress" {
    name        = "minecraft_ingress"
    description = "Allow inbound traffic on minecraft port"
    vpc_id      = aws_vpc.main.id

    ingress {
        from_port   = 25565
        to_port     = 25565
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

resource "aws_launch_template" "realm" {
    name = "realm"
    update_default_version = true

    instance_type = "t2.micro"
    image_id      = data.aws_ssm_parameter.ami_id.value
    ebs_optimized = true

    iam_instance_profile {
        name = aws_iam_instance_profile.realm.name
    }
    vpc_security_group_ids = [
        aws_security_group.minecraft_ingress.id,
        aws_default_security_group.main.id
    ]

    block_device_mappings {
        device_name = "/dev/xvda"
        ebs {
            volume_size = 8
        }
    }

    # instance_market_options {
    #     market_type = "spot"
    #     spot_options {
    #         instance_interruption_behavior = "terminate"

    #     }
    # }

    tag_specifications {
        resource_type = "instance"
        tags = local.tags
    }
}
