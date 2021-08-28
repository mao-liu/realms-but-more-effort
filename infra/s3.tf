resource "aws_s3_bucket" "realms" {
    bucket = "realms-but-more-effort"
}

resource "aws_ssm_parameter" "world_s3_path" {
    name  = "/realms/outputs/world_s3_path"
    type  = "String"
    value = "s3://${aws_s3_bucket.realms.id}/worlds/server.tar.gz"
}
