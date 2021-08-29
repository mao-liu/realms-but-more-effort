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

    instance_type = local.instance_type
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
            volume_size = 16
            delete_on_termination = true
        }
    }

    user_data = filebase64("${path.module}/userdata.sh")

    instance_market_options {
        market_type = "spot"
        spot_options {
            instance_interruption_behavior = "terminate"
            max_price = local.spot_price_maximum[local.instance_type]
            spot_instance_type = "one-time"
        }
    }

    tag_specifications {
        resource_type = "instance"
        tags = local.tags
    }
    tag_specifications {
        resource_type = "volume"
        tags = local.tags
    }
}

resource "aws_autoscaling_group" "realm" {
    name = "realm"
    min_size = 0
    max_size = 0

    launch_template {
        id      = aws_launch_template.realm.id
        version = aws_launch_template.realm.latest_version
    }

    vpc_zone_identifier = [
        aws_subnet.public["ap-southeast-2a"].id,
        aws_subnet.public["ap-southeast-2b"].id,
        aws_subnet.public["ap-southeast-2c"].id
    ]

    health_check_type = "EC2"

    wait_for_capacity_timeout = "0"

    tag {
        key   = "Project"
        value = local.tags["Project"]
        propagate_at_launch = true
    }

    lifecycle {
        ignore_changes = [
            min_size,
            max_size
        ]

    }
}
