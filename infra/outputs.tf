resource "aws_ssm_parameter" "world_s3_path" {
    name  = "/realms/outputs/world_s3_path"
    type  = "String"
    value = "s3://${aws_s3_bucket.realms.id}/worlds/server.tar.gz"
}

resource "aws_ssm_parameter" "route53_zone_id" {
    name  = "/realms/outputs/route53_zone_id"
    type  = "String"
    value = data.aws_route53_zone.aws.zone_id
}

resource "aws_ssm_parameter" "server_hostname" {
    name  = "/realms/outputs/server_hostname"
    type  = "String"
    value = "realms.${local.r53_domain}"
}

resource "aws_ssm_parameter" "asg_name" {
    name  = "/realms/outputs/server_asg_name"
    type  = "String"
    value = aws_autoscaling_group.realm.name
}
