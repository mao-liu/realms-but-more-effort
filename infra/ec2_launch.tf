data "aws_ssm_parameter" "ami_id" {
    name = "/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-ebs"
}

# resource "aws_launch_template" "realm" {
#     name = "realm"

#     instance_type = "t2.micro"
#     image_id = data.aws_ssm_parameter.ami_id.value

#     block_device_mappings {
#         device_name = "/dev/sda1"
#         ebs {
#             volume_size = 8
#         }
#     }

#     instance_market_options {
#         market_type = "spot"
#         spot_options {
#             instance_interruption_behavior = "terminate"

#         }
#     }

#     tag_specifications {
#         resource_type = "instance"
#         tags = local.tags
#     }
# }
