locals {
    gaia_name = "realms-gaia"
}

resource "aws_lambda_function" "gaia" {
  function_name    = local.gaia_name
  description      = "Minimalistic lambda function to check status and start realms"
  handler          = "app.lambda_handler"
  runtime          = "python3.8"

  filename         = "${local.gaia_name}.zip"
  source_code_hash = data.archive_file.gaia.output_base64sha256
  role             = aws_iam_role.realm.arn

  environment {
    variables = {
        SSM_ASG_NAME = "ssm://realms/outputs/server_asg_name"
    }
  }

}

data "archive_file" "gaia" {
  type        = "zip"
  output_path = "${local.gaia_name}.zip"

  source {
    filename = "app.py"
    content  = <<-PYTHON
    """Very minimalistic function queries and modifies ASG"""
    import boto3
    import os
    import json

    ASG = boto3.client('autoscaling')
    SSM = boto3.client('ssm)

    def _get_asg_name():
        ssm_path = os.environ['SSM_ASG_NAME'].replace('ssm:/', '')
        response = SSM.get_parameter(Name=ssm_path, WithDecryption=True)
        return response['Parameter']['Value']

    def _apigw_response(data: dict):
        response = {
            "isBase64Encoded": False,
            "statusCode": 200,
            "headers": {"Content-Type": "application/json"},
            "body": json.dumps(data)
        }
        return response

    def lambda_handler(event, contest):
        asg_name = _get_asg_name()
        asg_info = ASG.describe_auto_scaling_groups(
            AutoScalingGroupNames=[asg_name]
        )
        asg_info = asg_info['AutoScalingGroups'][0]
        print(json.dumps(asg_info))
        return _apigw_response(asg_info)

    PYTHON
  }
}

resource "aws_cloudwatch_log_group" "gaia" {
  name              = "/aws/lambda/${local.gaia_name}"
  retention_in_days = 30
}

resource "null_resource" "gaia_archiver_cleanup" {
  # clean up the zip file after lambda deployment
  triggers = {
    always_run = "${timestamp()}"
  }
  provisioner "local-exec" {
    command = "rm -f ${local.gaia_name}.zip"
  }
  depends_on = [aws_lambda_function.gaia]
}
